#ifndef _LB2PB_H_
#define _LB2PB_H_



#include "xstatus.h"


#define LB2PB_TABLE_ADDR	0x31008000

#define LBA_UNIT_SIZE			((u64)0x1000) //4kB
#define SLICE_BLOCK_SIZE		((u64)0x10*(u64)LBA_UNIT_SIZE) //64kB
#define SLICE_BLOCK_NUM			((u64)0x40000000/(u64)SLICE_BLOCK_SIZE) //0x4000 (< 0xFFFF)
#define HASH_BUCKET_NUM			((u64)0x1000)

#define LBA_UNIT_MASK			(LBA_UNIT_SIZE-1)
#define SLICE_BLOCK_MASK		(SLICE_BLOCK_SIZE-1)


#define NIL 0xFFFF


typedef struct transform_table {
	u32 logical_slice_block_addr : 31;
	u32 dirty : 1;
	u16 cold_prev;
	u16 cold_next;
	u16 hash_prev;
	u16 hash_next;
} TRANS_TABLE;

u32 get_dirty_lsba();
u32 get_lba_status();

void init_trans_table();
u32 get_pba_from_table(u64);

#endif
