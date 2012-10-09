# fstab

Linux fstab helper library

**WARNING**

Experimental code, will eat your fstab at some point.

# Usage

Adding a new entry to fstab:

    require 'fstab'

    # Use default /etc/fstab
    # With safe_mode only valid devices/filesystems will be added to fstab
    # Trying to add non existant device or filesystem will raise an exception
    #
    # :backup => true will create a timestamped fstab backup before saving
    # the changes
    fstab = Fstab.new '/etc/fstab', :safe_mode => true, 
                                    :backup => true, :backup_dir = '/etc/'
    
    # Asuming /dev/sda1 has a valid FS
    # The library will use the FS UUID automatically by default even if the block device path
    # was used as an argument. This is usually safer.
    fstab.add_fs '/dev/sda1', '/mnt', 'ext4', 'discard,errors=remount-ro', 0, 1

    # You can use filesystem UUID also
    fstab.add_fs '15baeabd-b419-4a69-a306-bc550dc8355f', '/mnt', 'ext4', 'discard,errors=remount-ro', 0, 1

    # List fstab entries
    fstab.entries.each do |key, val|
      puts val[:label] # FS label, may be nil
      puts val[:uuid]  # FS UUID, nil if entry marked as invalid
      puts val[:mount_point] 
      puts val[:type]
      puts val[:opts]
      puts val[:dump]
      puts val[:pass]
      puts val[:special] # special FS, i.e. not a block device
      puts val[:line_number] # line number for the FS in fstab
      puts val[:invalid] # the parser marked the entry as invalid 
    end

Checking if a device is present in /etc/fstab:

    fstab.has_device? '/dev/sda1' # => true
    # Assuming /dev/sda1 UUID is 15baeabd-b419-4a69-a306-bc550dc8355f
    fstab.has_device? '15baeabd-b419-4a69-a306-bc550dc8355f' # => true

Some other helper methods:

    # Return a hash of 'invalid' entries, i.e. device does not exist or the
    # entry is malformed
    fstab.invalid_entries
    # Automatically remove invalid entries creating a backup file
    fstab.remove_invalid_entries

    # Get FS UUID
    Fstab.get_uuid '/dev/sda1'

    # Get FS label, assuming it has one
    # return nil otherwise
    Fstab.get_label '/dev/sda1'

# Running the tests

    rake spec

# Copyright

Copyright (c) 2012 BVox World S.L.U. See LICENSE.txt for
further details.

