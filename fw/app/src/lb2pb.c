#include "lb2pb.h"


u32 coldest_index;
u32 hottest_index;
u32 idle_index;
TRANS_TABLE *trans_table_element;
u32 trans_hash_table[HASH_BUCKET_NUM];

u32 dirty_logical_slice_block_addr;
u32 lba_status;

u32 get_dirty_lsba()
{
	return dirty_logical_slice_block_addr;
}

u32 get_lba_status()
{
	return lba_status;
}

void init_mmu_and_cache()
{
	Xil_ICacheDisable();
	Xil_DCacheDisable();
	Xil_DisableMMU();

	u32 u;
	for (u = 0; u < 0x1000; u++)
	{
		if(u == 0x300 || u == 0x200)
			Xil_SetTlbAttributes(u * 0x100000, 0x10C12); // uncached & nonbuffered
		else if (u < 0x400)
			Xil_SetTlbAttributes(u * 0x100000, 0xC1E); // cached & buffered
		else
			Xil_SetTlbAttributes(u * 0x100000, 0x10C12); // uncached & nonbuffered
	}

	Xil_EnableMMU();
	Xil_ICacheEnable();
	Xil_DCacheEnable();
}

void init_trans_table()
{
	u32 i;

	trans_table_element = (TRANS_TABLE *) LB2PB_TABLE_ADDR;
	
	for(i=0;i<HASH_BUCKET_NUM;i++)
	{
		trans_hash_table[i] = NIL;
	}
	
	for(i=0;i<SLICE_BLOCK_NUM-1;i++)
	{
		trans_table_element[i].hash_next = i+1;
		trans_table_element[i].cold_next = NIL;
		trans_table_element[i].cold_prev = NIL;
	}
	
	trans_table_element[SLICE_BLOCK_NUM-1].hash_next = NIL;
	
	coldest_index = NIL;
	hottest_index = NIL;
	
	idle_index = 0;
}

u32 get_pba_from_table(u64 lba)
{
	u32 target_logical_slice_block_addr = (lba*LBA_UNIT_SIZE/SLICE_BLOCK_SIZE);
	u32 bucket_index = target_logical_slice_block_addr % HASH_BUCKET_NUM;
	u32 element_index = trans_hash_table[bucket_index];
	
	lba_status = 0;
	
	//return target_logical_slice_block_addr * (SLICE_BLOCK_SIZE/LBA_UNIT_SIZE);
	
	while(1)
	{
		if(element_index == NIL)
			break;
		
		if(trans_table_element[element_index].logical_slice_block_addr == target_logical_slice_block_addr)
			break;
		
		element_index = trans_table_element[element_index].hash_next;
	}
	
	if(element_index == NIL) //miss
	{
		lba_status |= 0x2; //must read new lba block from server
		if(idle_index == NIL) //idle list empty
		{	
			element_index = coldest_index;
			
			if(trans_table_element[element_index].dirty)
			{
				lba_status |= 0x1; //must send back old lba block to server
				dirty_logical_slice_block_addr = trans_table_element[element_index].logical_slice_block_addr;
			}
			
			u32 prev_element = trans_table_element[element_index].hash_prev;
			u32 next_element = trans_table_element[element_index].hash_next;
			
			if(next_element != NIL)
				trans_table_element[next_element].hash_prev = prev_element;
			if(prev_element != NIL)
				trans_table_element[prev_element].hash_next = next_element;
		}
		else
		{
			element_index = idle_index;
			idle_index = trans_table_element[idle_index].hash_next;
		}

		u32 entry = trans_hash_table[bucket_index];
		
		trans_table_element[element_index].logical_slice_block_addr = target_logical_slice_block_addr;
		trans_table_element[element_index].dirty = 0;
		trans_table_element[element_index].hash_next = entry;
		trans_table_element[element_index].hash_prev = NIL;
		if(entry != NIL)
			trans_table_element[entry].hash_prev = element_index;

		trans_hash_table[bucket_index] = element_index;
	}
	
	if(element_index == coldest_index)
		coldest_index = trans_table_element[element_index].cold_prev;
	else
	{
		u32 prev_element = trans_table_element[element_index].cold_prev;
		u32 next_element = trans_table_element[element_index].cold_next;
		
		if(prev_element != NIL)
			trans_table_element[prev_element].cold_next = next_element;
		if(next_element != NIL)
			trans_table_element[next_element].cold_prev = prev_element;
	}
	
	if(hottest_index != NIL)
		trans_table_element[hottest_index].cold_prev = element_index;
	trans_table_element[element_index].cold_next = hottest_index;
	trans_table_element[element_index].cold_prev = NIL;
	hottest_index = element_index;
	
	if(coldest_index == NIL)
		coldest_index = element_index;
	
	return (element_index*SLICE_BLOCK_SIZE/LBA_UNIT_SIZE);
}
