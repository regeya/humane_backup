#!/usr/local/bin/ruby
# McFly  -- a primitive Time Machine type implementation
# Does blessedly little sanity checking...beware
require 'fileutils'
require 'rubygems'
require 'active_support'
require 'find'
require 'digest/sha2'
include FileUtils

$maxsize = 50.megabytes

$rpool = "/media/mcfly/pool"

FOUR_K = 4.kilobytes
MIN_SIZE = 32.kilobytes

def stow_in_pool(get_dir)
Dir.chdir(get_dir)
Find.find(Dir.getwd).each do |f|
    if File.file?(f) and File.stat(f).size? and File.stat(f).readable?	
	filesize = File.size(f)
	if filesize <= MIN_SIZE
	    sum_md5 = Digest::SHA2.file(f).hexdigest 
	else
	    fopen = File.open(f)
	    fopen.seek(filesize/2).to_int
	    sum_md5 = Digest::SHA2.hexdigest(fopen.read(FOUR_K))
	    fopen.close
        end
	d,a,b,c = sum_md5.split(/^(..)(..)(..)(..)(.+)/)
	pooldir = "#{$rpool}/#{a}/#{b}/#{c}"
	mkdir_p(pooldir)
	poolfile = "#{pooldir}/#{sum_md5}"
	if not File.symlink?(f)
	  if File.exists?(poolfile)
	    if filesize == File.size(poolfile)
	      rm(f)
	      ln(poolfile,f)
              puts "#{poolfile} => #{f}"
            end
	  else  
	      rm(poolfile) if File.symlink?(poolfile)
	      ln(f,poolfile)
	      puts "#{f} => #{poolfile}"
	  end
        end   
      end
   end
end    

sd = "/media"
dd = "/media/mcfly/"

datestr = '%B %d, %Y (%A)'
shares = %w(ap_wire composition corel_gallery_1.0 fat_tony server storage_space)

current = "#{dd}/Current"
todays_date = Time.now.strftime(datestr)
dest = "#{dd}backups/#{todays_date}" 
incr = 14 #Number of iterations to keep

cruft = "#{dd}backups/#{incr.days.ago.strftime(datestr)}" # Keep at max 2 weeks worth

rm_rf(cruft) if File.exists?(cruft)
mkdir("#{dest}") if !(File.exists?(dest))
shares.each do |share|
	ldst= "--link-dest=\'#{current}/#{share}\'"
	mkdir("#{dest}/#{share}") if !(File.exists?(dest))
	system "lvcreate -L85G -s -n ssnap /dev/server/#{share}"
	system "mount /dev/server/ssnap /media/snapshot"
	system "/usr/bin/rsync-debian -rltgoD --checksum-seed=32767 --delete --exclude \'.AppleDB\' #{ldst} /media/snapshot/ \'#{dest}\'/#{share}"
	system "umount /media/snapshot"
	system "lvremove -f /dev/server/ssnap"
	stow_in_pool("#{dest}/#{share}")
end	
rm(current)
ln_s(dest,current)
chown("comp_1","users",dest)
system("find \'#{dest}\' -type d -name \".AppleDouble\" -print0 | xargs -0 chmod 0777")
system("find \'#{dest}\' -name \"*\" -not -name \".AppleDouble\" -print0 | xargs -0 chmod 0550")

#Clean the pool

Find.find($rpool) do |f|
    if File.file?(f)
       rm(f) if File.stat(f).nlink == 1
    end
end

#Back up issue tracker
system("rsync -a --delete /usr/local/redmine /media/backup/usr/local")
system("hg -R /usr/local/redmine/db_backup ci -m \"#{todays_date}\"")

