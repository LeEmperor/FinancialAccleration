// Bohdan Purtell

package mux_tb_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  class test_item extends uvm_sequence_item;
     function new (string name);
       super.new(name);
     endfunction
  endclass

  class test_sequencer extends uvm_sequencer#(test_item);
     `uvm_component_utils(test_sequencer);

     function new (string name, uvm_component parent);
       super.new(name, parent);
     endfunction
  endclass

  class test_sequence extends uvm_sequence#(test_item);
     `uvm_component_utils(test_sequence);

     function new (string name, uvm_component parent);
       super.new(name);
     endfunction

     virtual task body();
       mux_item req;

       repeat(50) begin
         req = mux_item::type_id::create("req");
         assert(req.randomize());
         start_item(req);
         finish_item(req);
       end
     endtask

  endclass

  class test_driver extends uvm_driver#(test_item);
    `uvm_component_utils(test_driver);
    virtual mux_interface v_if;

    function new (string name, uvm_component parent);
      super.new(parent);
    endfunction

    function enum_e build_phase (uvm_phase phase);
      super.build_phase(phase);

      // bind virtual if

    endfunction


    task run_phase(uvm_phase phase);

      test_item req;
      forever begin
        seq_item_port.get_next_item(seq);
        vif.a <= req.a;
        vif.b <= req.b;
        vif.sel <= req.sel;
        // vif.a <= req.a;
        @(posedge vif.clk);
        seq_item_port.item_done();
      end
    endtask
  endclass

  class test_monitor extends uvm_monitor#(test_monitor);
    `uvm_component_utils(test_driver);
    virtual mux_interface v_if;
    uvm_analysis_port#(test_item) a_port;

    function new (string name, uvm_component parent);
      super.new(parent);
      a_port = new("ap", this);
    endfunction

    function void build_phase ();
      super.build_phase(phase);
      if (!uvm_config#(virtual v_if)::get(this, "", "vif", "vif")); `uvm_fatal("bruh", "monitor: vif not set"); 
    endfunction

    task run_phase(uvm_phase phase);
      forever begin
        @(posedge vif.clk)

        test_item bruh_item = test_item::type_id::create("test1");
        bruh_item.a = v_if.a;
        bruh_item.b = v_if.b;
        bruh_item.sel = v_if.sel;
        bruh_item.out = v_if.out;
        a_port.write(bruh_item);
      end
    endtask
  endclass

  class test_agent extends uvm_agent;
    `uvm_component_utils(test_agent);
    test_sequencer sequencer;
    test_driver driver;
    test_monitor monitor;
    uvm_active_passive_enum is_active = UVM_ACTIVE;
    // virtual v_if;
    function new (string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);

      // new monitor
      monitor = test_monitor::type_id::create("mon", this);

      if (UVM_ACTIVE) begin
        sequencer = test_sequencer::type_id::create("sqr", this);
        driver = test_driver::type_id::create("drv", this);
      end
    endfunction

    function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);

      if (UVM_ACTIVE) begin
        drv.seq_item_port.connect(sqr.seq_item_export);
      end
    endfunction

    // task run_test ();
    //
    // endtask
  endclass

  class test_scoreboard extends uvm_component#(uvm_scoreboard);
    `uvm_component_utils(test_scoreboard);
    int cheese_counter = 0;

    uvm_analysis_imp#(test_item, test_scoreboard) imp;

    function new (string name, uvm_component parent);
      super.new(parent);
      imp = new("imp", this);
    endfunction

    function void write(test_item tr);
      bit expected = tr.sel ? tr.b : tr.a;
      cheese_counter ++ ;

      if (tr.out !== expected) begin
        `uvm_error("mismatch", $sformat("a=%0b...", tr.a, tr.b, tr.sel, tr.out);
      end
    endfunction

    function void report_phase(uvm_phase phase);
      `uvm_info("SB?", $sformat("checkced %0b...", cheese_counter), UVM_LOW)
    endfunction
  endclass

  class test_env extends uvm_env;
    `uvm_component_utils(test_env);

    test_agent agent;
    test_scoreboard scoreboard;

    function new (string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase (uvm_phase phase);
      super.build_phase(phase);
      agent = test_agent::type_id::create("agent", this);
      scoreboard = test_scoreboard::type_id::create("scoreboard", this);
    endfunction

    function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      agent.monitor.a_port.connect(scoreboard.imp);
    endfunction
  endclass

  class test_test extends uvm_test;
    `uvm_component_utils(test_test);

    test_env env1;

    function new (string name, uvm_component parent);
      super.new(parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      env1 = test_env::type_id::create("env", this);
    endfunction

    // function void connect_phase(uvm_phase phase);
    //   super.connect_phase(phase);
    // endfunction

    task run_phase(uvm_phase phase);
      phase.raise_object(this);
      seq = test_sequence::type_id::create("seq");
      seq.start(env.agent.sequencer);
      #20ns
      phase.drop_objection(this);
    endtask
  endclass

endpackage

