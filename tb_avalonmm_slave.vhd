library vunit_lib;
context vunit_lib.vunit_context;
context vunit_lib.com_context;
use vunit_lib.memory_pkg.all;
use vunit_lib.avalon_pkg.all;
use vunit_lib.bus_master_pkg.all;

library ieee;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;

entity tb_avalonmm_slave is
  generic(runner_cfg     : string;
          encoded_tb_cfg : string
         );
end entity;

architecture tb of tb_avalonmm_slave is

  -----------------------------------------------------------------------------
  -- Constants
  -----------------------------------------------------------------------------
  type tb_cfg_t is record
    data_width         : positive;
    burst_count        : positive;
    cycles             : positive;
    readdatavalid_prob : real;
    waitrequest_prob   : real;
  end record tb_cfg_t;

  impure function decode(encoded_tb_cfg : string) return tb_cfg_t is
  begin
    return (data_width         => positive'value(get(encoded_tb_cfg, "data_width")),
            burst_count        => positive'value(get(encoded_tb_cfg, "burst_count")),
            cycles             => positive'value(get(encoded_tb_cfg, "cycles")),
            readdatavalid_prob => real'value(get(encoded_tb_cfg, "readdatavalid_prob")),
            waitrequest_prob   => real'value(get(encoded_tb_cfg, "waitrequest_prob")));
  end function decode;

  constant tb_cfg : tb_cfg_t := decode(encoded_tb_cfg);

  constant CLK_TO_TIME : time := 1 ns * 1e9;

  constant CLK_100_FREQ   : real := 100000000.0;
  constant CLK_100_PERIOD : time := CLK_TO_TIME / CLK_100_FREQ;

  constant MEM_DATA_WIDTH_BITS   : integer := tb_cfg.data_width;
  constant MEM_SIZE_BYTES        : integer := tb_cfg.burst_count * integer(ceil(real(tb_cfg.data_width) / 8.0)) * tb_cfg.cycles;
  constant MEM_ADDR_WIDTH        : integer := integer(ceil(log2(real(MEM_SIZE_BYTES))));
  constant MEM_BURST_COUNT_WIDTH : integer := integer(ceil(log2(real(tb_cfg.burst_count)))) + 1;

  -----------------------------------------------------------------------------
  -- VUnit Setup
  -----------------------------------------------------------------------------

  constant tb_logger : logger_t := get_logger("tb");

  constant memory : memory_t := new_memory;
  constant buf    : buffer_t := allocate(memory, MEM_SIZE_BYTES); -- @suppress "Unused declaration"

  -- feel free to change the probabilities to check edge cases. We can change
  -- these even more as parameters passed in from the CLI later.
  -- You should be able to create multiple avalon slaves with this configuration
  -- and access the same memory space.
  constant avalon_slave_cfg : avalon_slave_t :=
      new_avalon_slave(memory => memory,
                       name => "avmm_vc",
                       readdatavalid_high_probability => tb_cfg.readdatavalid_prob,
                       waitrequest_high_probability   => tb_cfg.waitrequest_prob);

  -----------------------------------------------------------------------------
  -- AvalonMM VCIs
  -----------------------------------------------------------------------------
  component avalon_slave
    generic(avalon_slave : avalon_slave_t);
    port(
      clk           : in  std_logic;
      address       : in  std_logic_vector;
      byteenable    : in  std_logic_vector;
      burstcount    : in  std_logic_vector;
      waitrequest   : out std_logic;
      write         : in  std_logic;
      writedata     : in  std_logic_vector;
      read          : in  std_logic;
      readdata      : out std_logic_vector;
      readdatavalid : out std_logic
    );
  end component avalon_slave;

  -----------------------------------------------------------------------------
  -- Clock and Reset Signals
  -----------------------------------------------------------------------------

  signal clk_100 : std_logic := '1';

  signal mem_address       : std_logic_vector(MEM_ADDR_WIDTH - 1 downto 0)          := (others => '0');
  signal mem_writedata     : std_logic_vector(MEM_DATA_WIDTH_BITS - 1 downto 0)     := (others => '0');
  signal mem_readdata      : std_logic_vector(MEM_DATA_WIDTH_BITS - 1 downto 0)     := (others => '0');
  signal mem_byteenable    : std_logic_vector(MEM_DATA_WIDTH_BITS / 8 - 1 downto 0) := (others => '1'); -- @suppress "signal mem_byteenable is never written"
  signal mem_burstcount    : std_logic_vector(MEM_BURST_COUNT_WIDTH - 1 downto 0)   := (others => '0');
  signal mem_write         : std_logic                                              := '0';
  signal mem_read          : std_logic                                              := '0';
  signal mem_waitrequest   : std_logic                                              := '0';
  signal mem_readdatavalid : std_logic                                              := '0';

begin
  -----------------------------------------------------------------------------
  -- Clocks and resets
  -----------------------------------------------------------------------------
  clk_100 <= not clk_100 after CLK_100_PERIOD / 2.0;

  -----------------------------------------------------------------------------
  -- Avalon Slave
  -----------------------------------------------------------------------------
  avalon_slave_inst : component avalon_slave
    generic map(avalon_slave => avalon_slave_cfg)
    port map(
      clk           => clk_100,
      address       => mem_address,
      byteenable    => mem_byteenable,
      burstcount    => mem_burstcount,
      waitrequest   => mem_waitrequest,
      write         => mem_write,
      writedata     => mem_writedata,
      read          => mem_read,
      readdata      => mem_readdata,
      readdatavalid => mem_readdatavalid
    );

  -----------------------------------------------------------------------------
  -- Testing process
  -----------------------------------------------------------------------------

  main : process
    variable data : natural := 0;
  begin
    test_runner_setup(runner, runner_cfg);
    wait until rising_edge(clk_100);

    -----------------------------------------------------------------------------
    -- The lines below set the test output verbosity, which can help debug
    -----------------------------------------------------------------------------

    --    set_format(display_handler, verbose, true);
    --    show(tb_logger, display_handler, verbose);
    --    show(master_logger, display_handler, verbose);
    --    show(com_logger, display_handler, verbose);
    --
    --    wait_clocks_200(num => 1);

    -----------------------------------------------------------------------------

    -----------------------------------------------------------------------------
    -- This is a very basic test that proves we can burst read and write to the
    -- memory attached to the AvalonMM Slave
    -----------------------------------------------------------------------------
    if run("Burst_Test") then
      info(tb_logger, "Writing...");
      data := 0;
      mem_address       <= (others => 'U');
      mem_burstcount(0) <= '1';

      -----------------------------------------------------------------------------
      -- Write some data. This is set up to write MEM_BURST_COUNT words per cycle.
      -----------------------------------------------------------------------------
      
      for i in 0 to (tb_cfg.cycles * tb_cfg.burst_count) - 1 loop
        if i mod tb_cfg.burst_count =  0 then
            mem_address    <= (others => 'U');
            mem_burstcount <= (others => 'U');
            mem_writedata  <= (others => 'U');
            mem_write <= '0';            
            wait until rising_edge(clk_100);
            mem_address    <= std_logic_vector(to_unsigned(i, mem_address'length));
            mem_burstcount <= std_logic_vector(to_unsigned(tb_cfg.burst_count, mem_burstcount'length));
            mem_writedata <= std_logic_vector(to_unsigned(data, mem_writedata'length));
            mem_write     <= '1';
          else
            mem_write     <= '1';
            mem_writedata <= std_logic_vector(to_unsigned(i, mem_writedata'length));
          end if;
          wait until rising_edge(clk_100) and mem_waitrequest = '0';
        mem_write      <= '0';
        data := data + 1;
      end loop;
      mem_address    <= (others => 'U');
      mem_burstcount <= (others => 'U');
      mem_writedata  <= (others => 'U');
      
      wait until rising_edge(clk_100);

      -----------------------------------------------------------------------------
      -- Read the data back
      -----------------------------------------------------------------------------
      
      info(tb_logger, "Reading...");
      data := 0;
      for cycle in 0 to tb_cfg.cycles - 1 loop
        wait until rising_edge(clk_100);
        mem_read       <= '1';
        mem_burstcount <= std_logic_vector(to_unsigned(tb_cfg.burst_count, mem_burstcount'length));
        mem_address    <= std_logic_vector(to_unsigned(tb_cfg.burst_count*cycle, mem_address'length));
        wait until rising_edge(clk_100) and mem_waitrequest = '0';
        mem_read       <= '0';

        for j in 0 to tb_cfg.burst_count - 1 loop
          wait until rising_edge(clk_100) and mem_readdatavalid = '1';
          check_equal(mem_readdata, std_logic_vector(to_unsigned(data, mem_readdata'length)), "readdata");
          data := data + 1;
        end loop;
      end loop;
    end if;

    test_runner_cleanup(runner);        -- Simulation ends here
    wait;
  end process;

  -- Set up watchdog so the TB doesn't run forever
  test_runner_watchdog(runner, 10 us);
end architecture;
