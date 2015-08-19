# ext4scan
History:
I had a 2TB drive die some days ago and was able to copy ~2/3 of the drive to a recovery drive. I wanted to generate a manifest of damaged files from the ext4 partition on the recovery drive, but there is no easy way to scan the 157 million blocks that did not get dd'd before the drive became completely unusable, so here is my solution to the problem. This should also work fine for checking what files are using dead spots

NOTE: Filesystem blocks are not the same as physical blocks, and some math is needed before using this tool.
