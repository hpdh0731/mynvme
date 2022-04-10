#include "xparameters.h"
#include "xstatus.h"
#include "lb2pb.h"
#include "gpio.h"
#include "pcie_req.h"
#include "nvme_cmd.h"


int main()
{
    xil_printf("Hello World\r\n");
	

	init_gpio();
	init_mmu_and_cache();
	init_trans_table();
	wait_pcie_init();

	u32 ctrl_state = 0;


    while(1)
    {
		ctrl_state = update_db_reg(ctrl_state);
		
    	if(ctrl_state == 0) // off
    	{

    	}
    	else if(ctrl_state == 1) // booting
    	{
			reset_local_db_reg();
			write_pl_reg(0x1c, 0x1); //ready
			if(read_pl_reg(0x1c) == 0x1)
			{
				ctrl_state = 2;
				xil_printf("***Controller Ready***\r\n");
			}
    	}
    	else if(ctrl_state == 2) // running
		{
    		handle_nvme_req();
		}
    	else if(ctrl_state == 3) // shutdown
		{
    		xil_printf("***Controller Shutdown***\r\n");
    		u32 csts = read_pl_reg(0x1c) & 0x3;
    		write_pl_reg(0x1c,csts | 0x4); //Shutdown processing occurring
    		write_pl_reg(0x1c,csts | 0x8); //Shutdown processing complete

    		ctrl_state = 4; // reset
		}
    	else if(ctrl_state == 4) // reset
		{
    		xil_printf("***Controller Reset***\r\n");
    		reset_local_db_reg();

			write_pl_reg(0x1c,0x0); //Normal operation & not ready
		}
		else if(ctrl_state == 5) // wait
		{
		}
    }

    return 0;
}
