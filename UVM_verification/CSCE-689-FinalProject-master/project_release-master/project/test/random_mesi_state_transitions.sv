class random_mesi_state_transitions extends base_test;

    //component macro
    `uvm_component_utils(random_mesi_state_transitions)

    //Constructor
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    //UVM build phase
    function void build_phase(uvm_phase phase);
        uvm_config_wrapper::set(this, "tb.vsequencer.run_phase", "default_sequence", random_mesi_state_seq::type_id::get());
        super.build_phase(phase);
    endfunction : build_phase

    //UVM run phase()
    task run_phase(uvm_phase phase);
        `uvm_info(get_type_name(), "Executing Random mesi state transitions test" , UVM_LOW)
    endtask: run_phase

endclass : random_mesi_state_transitions


// Sequence for a Random mesi state transitions
class random_mesi_state_seq extends base_vseq;
    //object macro
    `uvm_object_utils(random_mesi_state_seq)

    cpu_transaction_c trans;

    //constructor
    function new (string name="random_mesi_state_seq");
        super.new(name);
    endfunction : new

    virtual task body();
    
       //Random MESI FSM transitions
        repeat(10)
	`uvm_do_on_with(trans, p_sequencer.cpu_seqr[mp], {access_cache_type == DCACHE_ACC; address == 32'h4000_0800;})
    endtask


endclass : random_mesi_state_seq

