# humane-backup
Humane Backup - A Linux home directory snapshot backup solution for human beings.

All that is here so far is a copy of the rsync-backed script I wrote years ago.  I hadn't kept the rewrite in this repository, and it was lost to the ages long ago.  If anything, this is a good exampe right now of how *not* to write a backup system.

The plan at this point is to retain the BackupPC-style backing store for checksummed files, but replace rsync with findutils, and track archived/obsolete files by using a sqlite db.
