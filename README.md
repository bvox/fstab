# fstab

Linux fstab helper library

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
    fstab.add_device '/dev/sda1', '/mnt', 'ext4', 'discard,errors=remount-ro', 0, 1

    # You can use filesystem UUID also
    fstab.add_device '15baeabd-b419-4a69-a306-bc550dc8355f', '/mnt', 'ext4', 'discard,errors=remount-ro', 0, 1

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

# Running the tests

    rake spec

# Copyright

Copyright (c) 2012 BVox World S.L.U. See LICENSE.txt for
further details.

