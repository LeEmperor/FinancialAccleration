// Bohdan Purtell
// UF
// Agent test

module test_tb();

class test_agent extends uvm_agent;
  `uvm_component_utils(test_agent)

  test_sequencer sequencer;
  test_driver driver;
  test_monitor monitor;

  function new( string name, 
                uvm_component, parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    sequencer = test_sequencer::type_id::create("sequencer", this);
    driver = test_driver::type_id::create("driver", this);
    monitor = test_monitor::type_id::create("monitor", this);
  endfunction

  typedef enum {
    unknown_error = -1,
    no_error = 0,
    bruh_error = 1
  } error_e;

  function error_e connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    driver.seq_item_port.connect(sequencer.seq_item_export);
  endfunction

endmodule




