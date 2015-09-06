# ext4scan
History:
I had a 2TB drive die some days ago and was able to copy ~2/3 of the drive to a recovery drive. I wanted to generate a manifest of damaged files from the ext4 partition on the recovery drive, but there is no easy way to scan the 157 million blocks that did not get dd'd before the drive became completely unusable, so here is my solution to the problem. This should also work fine for checking what files are using dead spots

NOTE: Filesystem blocks are not the same as physical blocks, and some math is needed before using this tool.

V2: I completed the V1, then discovered the 2.5 second penalty per block was too severe a time penalty, unless you need process a massive range like me, **audit and use ext4scanv1**.

Performance note: If you run one debugfs instance on the side, do a random icheck and ncheck, and leave it sit at the prompt, it will hold the target's supernode data in the disk cache, and these scripts will use that instead of thrashing the target drive.
