#include "gpio.h"

volatile XGpioPs gpio_inst;
volatile u32 write_reg_trigger = 0;

void wait_pcie_reset()
{
	while( XGpioPs_Read(&gpio_inst, 2) & 0x1 == 0)
	{
		xil_printf("wait pcie reset\r\n");
		sleep(1);
	};
}

void init_gpio()
{
	XGpioPs_Config *gpio_cfg = XGpioPs_LookupConfig(XPAR_PS7_GPIO_0_DEVICE_ID);
	XGpioPs_CfgInitialize(&gpio_inst, gpio_cfg, gpio_cfg->BaseAddr);
	XGpioPs_SetDirection(&gpio_inst, 2, 0xffffffff);
	XGpioPs_SetDirection(&gpio_inst, 3, 0xffffffff);
	XGpioPs_SetOutputEnable(&gpio_inst, 2, 0xffffffff);
	XGpioPs_SetOutputEnable(&gpio_inst, 3, 0xffffffff);
	
	wait_pcie_reset();
	
	xil_printf("pcie init done\r\n");
	
	XGpioPs_WritePin(&gpio_inst, 54+32, 0);
	
}

u32 read_pl_reg(u32 addr)
{
	/*XGpioPs_Write(&gpio_inst, 3, (addr & 0x1fff) | write_reg_trigger );
	return XGpioPs_Read(&gpio_inst, 2);*/
	
	return *((volatile u32* )(0x80000000 + addr));
}

void write_pl_reg(u32 addr, u32 data)
{
	/*XGpioPs_Write(&gpio_inst, 2, data);
	write_reg_trigger ^= 0x4000;
	XGpioPs_Write(&gpio_inst, 3, (addr & 0x1fff) | write_reg_trigger);*/
	
	*((volatile u32* )(0x80000000 + addr)) = data;
}

void start_pcie_req()
{
	static u32 value = 0;
	if(value)
		value = 0;
	else
		value = 1;
	XGpioPs_WritePin(&gpio_inst, 54+32, value);
	
	//*((volatile u32* )(0x80000C00)) = 0;
}
