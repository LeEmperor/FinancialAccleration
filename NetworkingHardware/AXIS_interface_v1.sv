interface AXIS_interface #(
  parameter int WIDTH = 32
) ();
  logic [WIDTH - 1 : 0] t_data;
  logic t_valid, t_ready, t_last;
  logic [WIDTH / 8 - 1 : 0] byte_enable; // quelle bits ont valides

  modport sender_v1 (
    output t_data,
    output t_valid,
    output t_last,
    output byte_enable,

    input t_ready
  );

  modport receiver_v1 (
    input t_data,
    input t_valid, // quand c'est valide, le data dans t_data on peut utiliser pour envoyer de data
    input t_last,
    input byte_enable,

    output t_ready
  );
endinterface

