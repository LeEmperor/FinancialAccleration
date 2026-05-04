// =============================================================================
// order_book.sv
// Arty A7-100T ITCH Demo
//
// Simplified single-symbol order book.
// Tracks up to ORDER_SLOTS resting orders and aggregates them into
// NUM_LEVELS price levels per side.
//
// For a demo on A7-100T we use:
//   ORDER_SLOTS = 256  (order reference table — small but sufficient for demo)
//   NUM_LEVELS  = 8    (top 8 price levels each side)
//
// In production you'd use URAM hash tables; here we use BRAM-friendly arrays.
//
// Outputs:
//   Best bid price/size and best ask price/size (BBO)
//   Updated strobe whenever BBO changes
// =============================================================================

module order_book #(
    parameter int ORDER_SLOTS = 256,
    parameter int NUM_LEVELS  = 8
)(
    input  logic        clk,
    input  logic        rst_n,

    // From ITCH decoder
    // Add Order
    input  logic        add_valid,
    input  logic [63:0] add_order_ref,
    input  logic        add_side,      // 1=bid, 0=ask
    input  logic [31:0] add_shares,
    input  logic [31:0] add_price,

    // Delete Order
    input  logic        del_valid,
    input  logic [63:0] del_order_ref,

    // Order Replace (treated as delete + add)
    input  logic        rep_valid,
    input  logic [63:0] rep_orig_ref,
    input  logic [63:0] rep_new_ref,
    input  logic [31:0] rep_shares,
    input  logic [31:0] rep_price,

    // Order Executed (partial or full)
    input  logic        exe_valid,
    input  logic [63:0] exe_order_ref,
    input  logic [31:0] exe_shares,

    // Order Cancel (partial size reduction)
    input  logic        can_valid,
    input  logic [63:0] can_order_ref,
    input  logic [31:0] can_shares,

    // BBO outputs
    output logic [31:0] best_bid_price,
    output logic [31:0] best_bid_size,
    output logic [31:0] best_ask_price,
    output logic [31:0] best_ask_size,
    output logic        bbo_updated     // 1-cycle strobe on any BBO change
);

    // -------------------------------------------------------------------------
    // Order reference table
    // Key:   order_ref[7:0] (low 8 bits — sufficient for demo)
    // Value: { valid, side, price, shares }
    // -------------------------------------------------------------------------
    logic          ord_valid  [ORDER_SLOTS];
    logic          ord_side   [ORDER_SLOTS];
    logic [31:0]   ord_price  [ORDER_SLOTS];
    logic [31:0]   ord_shares [ORDER_SLOTS];
    logic [63:0]   ord_ref    [ORDER_SLOTS]; // full ref for collision check

    // -------------------------------------------------------------------------
    // Price level tables — bid and ask sides
    // Each entry: { valid, price, agg_size }
    // -------------------------------------------------------------------------
    logic          bid_valid  [NUM_LEVELS];
    logic [31:0]   bid_price  [NUM_LEVELS];
    logic [31:0]   bid_size   [NUM_LEVELS];

    logic          ask_valid  [NUM_LEVELS];
    logic [31:0]   ask_price  [NUM_LEVELS];
    logic [31:0]   ask_size   [NUM_LEVELS];

    // -------------------------------------------------------------------------
    // Internal signals
    // -------------------------------------------------------------------------
    // Three-stage pipeline for ops that read ord[] arrays:
    //   Stage 1 (*_DEL/EXE/CAN): op_ref → 256:1 mux → register lu_side/price/shares
    //   Stage 2 (OP_LV):         lu_price → find_level comparators → register lu_level
    //   Stage 3 (*_CMT):         lu_level → bid/ask_size index + arithmetic → write-back
    // Each stage fits in one 10 ns period; total 3 cycles per op (fine at 100 Mb/s).
    typedef enum logic [4:0] {
        OP_IDLE,
        OP_ADD,     OP_ADD_CMT,
        OP_DEL,     OP_DEL_CMT,
        OP_REP_DEL, OP_REP_DEL_CMT, OP_REP_ADD,
        OP_EXE,     OP_EXE_CMT,
        OP_CAN,     OP_CAN_CMT,
        OP_LV
    } op_t;

    op_t            op_state;
    op_t            pending_op;   // next state after OP_LV
    (* max_fanout = 16 *) logic [63:0] op_ref, op_new_ref;
    logic [31:0]    op_shares, op_price;
    logic           op_side;

    // Registered pipeline values shared across the three stages.
    logic [7:0]  lu_slot;
    logic        lu_valid, lu_side;
    logic [31:0] lu_price, lu_shares;
    logic [3:0]  lu_level;        // find_level result, registered in OP_LV

    // BBO tracking
    logic [31:0]    r_best_bid_price, r_best_bid_size;
    logic [31:0]    r_best_ask_price, r_best_ask_size;

    assign best_bid_price = r_best_bid_price;
    assign best_bid_size  = r_best_bid_size;
    assign best_ask_price = r_best_ask_price;
    assign best_ask_size  = r_best_ask_size;

    // -------------------------------------------------------------------------
    // BBO reduction helpers — pure combinational, no loop-carried state.
    // Synthesis sees independent comparators at each tree level.
    // -------------------------------------------------------------------------
    typedef struct packed {
        logic        vld;
        logic [31:0] px;
        logic [31:0] sz;
    } bbo_entry_t;

    function automatic bbo_entry_t pick_bid(bbo_entry_t a, bbo_entry_t b);
        if (!a.vld) return b;
        if (!b.vld) return a;
        return (a.px >= b.px) ? a : b;
    endfunction

    function automatic bbo_entry_t pick_ask(bbo_entry_t a, bbo_entry_t b);
        if (!a.vld) return b;
        if (!b.vld) return a;
        return (a.px <= b.px) ? a : b;
    endfunction

    // -------------------------------------------------------------------------
    // Helper: find price level index (returns NUM_LEVELS if not found)
    // -------------------------------------------------------------------------
    function automatic logic [3:0] find_level(
        input logic        side,
        input logic [31:0] price
    );
        if (side) begin // bid
            for (int i = 0; i < NUM_LEVELS; i++) begin
                if (bid_valid[i] && bid_price[i] == price)
                    return 4'(i);
            end
        end else begin // ask
            for (int i = 0; i < NUM_LEVELS; i++) begin
                if (ask_valid[i] && ask_price[i] == price)
                    return 4'(i);
            end
        end
        return 4'(NUM_LEVELS);
    endfunction

    // -------------------------------------------------------------------------
    // Helper: find free level slot
    // -------------------------------------------------------------------------
    function automatic logic [3:0] free_level(input logic side);
        if (side) begin
            for (int i = 0; i < NUM_LEVELS; i++) begin
                if (!bid_valid[i]) return 4'(i);
            end
        end else begin
            for (int i = 0; i < NUM_LEVELS; i++) begin
                if (!ask_valid[i]) return 4'(i);
            end
        end
        return 4'(NUM_LEVELS);
    endfunction

    // -------------------------------------------------------------------------
    // Main FSM
    // -------------------------------------------------------------------------
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            op_state <= OP_IDLE;
            for (int i = 0; i < ORDER_SLOTS; i++) begin
                ord_valid[i]  <= 1'b0;
                ord_side[i]   <= 1'b0;
                ord_price[i]  <= '0;
                ord_shares[i] <= '0;
                ord_ref[i]    <= '0;
            end
            for (int i = 0; i < NUM_LEVELS; i++) begin
                bid_valid[i] <= 1'b0; bid_price[i] <= '0; bid_size[i] <= '0;
                ask_valid[i] <= 1'b0; ask_price[i] <= '0; ask_size[i] <= '0;
            end
        end else begin
            case (op_state)
                // --------------------------------------------------------------
                OP_IDLE: begin
                    // Priority: add > del > rep > exe > can
                    if (add_valid) begin
                        op_state  <= OP_ADD;
                        op_ref    <= add_order_ref;
                        op_side   <= add_side;
                        op_shares <= add_shares;
                        op_price  <= add_price;
                    end else if (del_valid) begin
                        op_state <= OP_DEL;
                        op_ref   <= del_order_ref;
                    end else if (rep_valid) begin
                        op_state   <= OP_REP_DEL;
                        op_ref     <= rep_orig_ref;
                        op_new_ref <= rep_new_ref;
                        op_shares  <= rep_shares;
                        op_price   <= rep_price;
                    end else if (exe_valid) begin
                        op_state  <= OP_EXE;
                        op_ref    <= exe_order_ref;
                        op_shares <= exe_shares;
                    end else if (can_valid) begin
                        op_state  <= OP_CAN;
                        op_ref    <= can_order_ref;
                        op_shares <= can_shares;
                    end
                end

                // --------------------------------------------------------------
                // Stage 1: register slot check + copy op_* into lu_* so the
                // op_price→find_level→bid_size path is broken at two FFs.
                OP_ADD: begin
                    automatic logic [7:0] s = op_ref[7:0];
                    lu_slot    <= s;
                    lu_valid   <= ord_valid[s]; // !lu_valid → slot free → write
                    lu_side    <= op_side;
                    lu_price   <= op_price;
                    lu_shares  <= op_shares;
                    pending_op <= OP_ADD_CMT;
                    op_state   <= OP_LV;
                end

                // Stage 3: lu_level registered; op_ref still holds the ref to store.
                OP_ADD_CMT: begin
                    automatic logic [3:0] fl;
                    if (!lu_valid) begin
                        ord_valid[lu_slot]  <= 1'b1;
                        ord_ref[lu_slot]    <= op_ref;
                        ord_side[lu_slot]   <= lu_side;
                        ord_price[lu_slot]  <= lu_price;
                        ord_shares[lu_slot] <= lu_shares;
                        if (lu_level < NUM_LEVELS) begin
                            if (lu_side)
                                bid_size[lu_level] <= bid_size[lu_level] + lu_shares;
                            else
                                ask_size[lu_level] <= ask_size[lu_level] + lu_shares;
                        end else begin
                            fl = free_level(lu_side);
                            if (fl < NUM_LEVELS) begin
                                if (lu_side) begin
                                    bid_valid[fl] <= 1'b1;
                                    bid_price[fl] <= lu_price;
                                    bid_size[fl]  <= lu_shares;
                                end else begin
                                    ask_valid[fl] <= 1'b1;
                                    ask_price[fl] <= lu_price;
                                    ask_size[fl]  <= lu_shares;
                                end
                            end
                        end
                    end
                    op_state <= OP_IDLE;
                end

                // --------------------------------------------------------------
                // Stage 1: register ord[] lookup (breaks op_ref→256:1 mux path).
                OP_DEL: begin
                    automatic logic [7:0] s = op_ref[7:0];
                    lu_slot   <= s;
                    lu_valid  <= ord_valid[s];
                    lu_side   <= ord_side[s];
                    lu_price  <= ord_price[s];
                    lu_shares <= ord_shares[s];
                    pending_op <= OP_DEL_CMT;
                    op_state   <= OP_LV;
                end

                // Stage 2 (shared): run find_level on registered lu_price/lu_side,
                // store result in lu_level. Breaks lu_price→comparators→*_size_reg.
                OP_LV: begin
                    lu_level <= find_level(lu_side, lu_price);
                    op_state <= pending_op;
                end

                // Stage 3: lu_level is registered — pure index + arithmetic, no comparators.
                OP_DEL_CMT: begin
                    if (lu_valid) begin
                        ord_valid[lu_slot] <= 1'b0;
                        if (lu_level < NUM_LEVELS) begin
                            if (lu_side) begin
                                if (bid_size[lu_level] > lu_shares)
                                    bid_size[lu_level] <= bid_size[lu_level] - lu_shares;
                                else begin bid_valid[lu_level] <= 1'b0; bid_size[lu_level] <= '0; end
                            end else begin
                                if (ask_size[lu_level] > lu_shares)
                                    ask_size[lu_level] <= ask_size[lu_level] - lu_shares;
                                else begin ask_valid[lu_level] <= 1'b0; ask_size[lu_level] <= '0; end
                            end
                        end
                    end
                    op_state <= OP_IDLE;
                end

                // --------------------------------------------------------------
                OP_REP_DEL: begin
                    automatic logic [7:0] s = op_ref[7:0];
                    lu_slot    <= s;
                    lu_valid   <= ord_valid[s];
                    lu_side    <= ord_side[s];
                    lu_price   <= ord_price[s];
                    lu_shares  <= ord_shares[s];
                    pending_op <= OP_REP_DEL_CMT;
                    op_state   <= OP_LV;
                end

                OP_REP_DEL_CMT: begin
                    if (lu_valid) begin
                        op_side            <= lu_side;
                        ord_valid[lu_slot] <= 1'b0;
                        if (lu_level < NUM_LEVELS) begin
                            if (lu_side) begin
                                if (bid_size[lu_level] > lu_shares)
                                    bid_size[lu_level] <= bid_size[lu_level] - lu_shares;
                                else begin bid_valid[lu_level] <= 1'b0; bid_size[lu_level] <= '0; end
                            end else begin
                                if (ask_size[lu_level] > lu_shares)
                                    ask_size[lu_level] <= ask_size[lu_level] - lu_shares;
                                else begin ask_valid[lu_level] <= 1'b0; ask_size[lu_level] <= '0; end
                            end
                        end
                    end
                    op_ref   <= op_new_ref;
                    op_state <= OP_REP_ADD;
                end

                // op_ref was updated to op_new_ref in OP_REP_DEL_CMT;
                // op_side was captured from the original order then.
                // Route through OP_LV → OP_ADD_CMT to reuse the same commit logic.
                OP_REP_ADD: begin
                    automatic logic [7:0] s = op_ref[7:0];
                    lu_slot    <= s;
                    lu_valid   <= ord_valid[s];
                    lu_side    <= op_side;
                    lu_price   <= op_price;
                    lu_shares  <= op_shares;
                    pending_op <= OP_ADD_CMT;
                    op_state   <= OP_LV;
                end

                // --------------------------------------------------------------
                OP_EXE: begin
                    automatic logic [7:0] s = op_ref[7:0];
                    lu_slot    <= s;
                    lu_valid   <= ord_valid[s];
                    lu_side    <= ord_side[s];
                    lu_price   <= ord_price[s];
                    lu_shares  <= ord_shares[s];
                    pending_op <= OP_EXE_CMT;
                    op_state   <= OP_LV;
                end

                OP_EXE_CMT: begin
                    if (lu_valid) begin
                        if (lu_shares <= op_shares) begin
                            ord_valid[lu_slot] <= 1'b0;
                            if (lu_level < NUM_LEVELS) begin
                                if (lu_side) begin
                                    if (bid_size[lu_level] > lu_shares)
                                        bid_size[lu_level] <= bid_size[lu_level] - lu_shares;
                                    else begin bid_valid[lu_level] <= 1'b0; bid_size[lu_level] <= '0; end
                                end else begin
                                    if (ask_size[lu_level] > lu_shares)
                                        ask_size[lu_level] <= ask_size[lu_level] - lu_shares;
                                    else begin ask_valid[lu_level] <= 1'b0; ask_size[lu_level] <= '0; end
                                end
                            end
                        end else begin
                            ord_shares[lu_slot] <= lu_shares - op_shares;
                            if (lu_level < NUM_LEVELS) begin
                                if (lu_side)
                                    bid_size[lu_level] <= bid_size[lu_level] - op_shares;
                                else
                                    ask_size[lu_level] <= ask_size[lu_level] - op_shares;
                            end
                        end
                    end
                    op_state <= OP_IDLE;
                end

                // --------------------------------------------------------------
                OP_CAN: begin
                    automatic logic [7:0] s = op_ref[7:0];
                    lu_slot    <= s;
                    lu_valid   <= ord_valid[s];
                    lu_side    <= ord_side[s];
                    lu_price   <= ord_price[s];
                    lu_shares  <= ord_shares[s];
                    pending_op <= OP_CAN_CMT;
                    op_state   <= OP_LV;
                end

                OP_CAN_CMT: begin
                    if (lu_valid) begin
                        ord_shares[lu_slot] <= lu_shares - op_shares;
                        if (lu_level < NUM_LEVELS) begin
                            if (lu_side)
                                bid_size[lu_level] <= bid_size[lu_level] - op_shares;
                            else
                                ask_size[lu_level] <= ask_size[lu_level] - op_shares;
                        end
                    end
                    op_state <= OP_IDLE;
                end

                default: op_state <= OP_IDLE;
            endcase
        end
    end

    // -------------------------------------------------------------------------
    // BBO recomputation — pipelined 2-stage reduction tree.
    //
    // Stage 1 (bbo_l1_*): 4 independent pair comparisons directly from the
    //   level arrays.  Path: bid/ask_price_reg[i] → pick_* → bbo_l1_reg
    //   (~8-10 LUT levels, short nets, low fanout).
    //
    // Stage 2 (r_best_*): final 3 comparisons from registered stage-1 values.
    //   Path: bbo_l1_reg → pick_* × 3 → r_best_*_reg
    //   (~8-10 LUT levels, short nets, low fanout).
    //
    // Adds 1 cycle of extra latency to BBO output — invisible at 100 Mb/s.
    // -------------------------------------------------------------------------
    bbo_entry_t bbo_l1_bid[4], bbo_l1_ask[4];

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            for (int i = 0; i < 4; i++) begin
                bbo_l1_bid[i] <= '{1'b0, '0, '0};
                bbo_l1_ask[i] <= '{1'b0, '0, '0};
            end
        end else begin
            for (int i = 0; i < 4; i++) begin
                bbo_l1_bid[i] <= pick_bid(
                    '{bid_valid[2*i],   bid_price[2*i],   bid_size[2*i]},
                    '{bid_valid[2*i+1], bid_price[2*i+1], bid_size[2*i+1]});
                bbo_l1_ask[i] <= pick_ask(
                    '{ask_valid[2*i],   ask_price[2*i],   ask_size[2*i]},
                    '{ask_valid[2*i+1], ask_price[2*i+1], ask_size[2*i+1]});
            end
        end
    end

    // Stage 2a: two pair comparisons from registered l1 values.
    bbo_entry_t bbo_l2_bid[2], bbo_l2_ask[2];

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            for (int i = 0; i < 2; i++) begin
                bbo_l2_bid[i] <= '{1'b0, '0, '0};
                bbo_l2_ask[i] <= '{1'b0, '0, '0};
            end
        end else begin
            for (int i = 0; i < 2; i++) begin
                bbo_l2_bid[i] <= pick_bid(bbo_l1_bid[2*i], bbo_l1_bid[2*i+1]);
                bbo_l2_ask[i] <= pick_ask(bbo_l1_ask[2*i], bbo_l1_ask[2*i+1]);
            end
        end
    end

    // Stage 2b: final pick + BBO update from registered l2 values.
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            r_best_bid_price <= '0;
            r_best_bid_size  <= '0;
            r_best_ask_price <= '0;
            r_best_ask_size  <= '0;
            bbo_updated      <= 1'b0;
        end else begin
            automatic bbo_entry_t bid_best, ask_best;
            automatic logic [31:0] new_bid_px, new_bid_sz;
            automatic logic [31:0] new_ask_px, new_ask_sz;

            bid_best = pick_bid(bbo_l2_bid[0], bbo_l2_bid[1]);
            ask_best = pick_ask(bbo_l2_ask[0], bbo_l2_ask[1]);

            new_bid_px = bid_best.vld ? bid_best.px : '0;
            new_bid_sz = bid_best.vld ? bid_best.sz : '0;
            new_ask_px = ask_best.vld ? ask_best.px : '0;
            new_ask_sz = ask_best.vld ? ask_best.sz : '0;

            bbo_updated      <= (new_bid_px != r_best_bid_price) ||
                                (new_bid_sz != r_best_bid_size)  ||
                                (new_ask_px != r_best_ask_price) ||
                                (new_ask_sz != r_best_ask_size);
            r_best_bid_price <= new_bid_px;
            r_best_bid_size  <= new_bid_sz;
            r_best_ask_price <= new_ask_px;
            r_best_ask_size  <= new_ask_sz;
        end
    end

endmodule
