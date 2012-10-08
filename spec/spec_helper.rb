$: << File.join(File.dirname(__FILE__), '../lib')
require 'fstab'

def get_first_blkid
  blkid = `/sbin/blkid`.lines.first
  uuid = blkid.match(/UUID="(.*?)"\s+/)[1] 
  label = blkid.match(/LABEL="(.*?)"\s+/)[1] rescue nil
  type = blkid.match(/TYPE="(.*?)"\s+/)[1]
  pdev = blkid.match(/(\/dev\/.*?):/)[1] 
  return pdev, uuid, label, type
end
