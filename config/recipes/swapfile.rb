# Creates and enables swapfiles on machines.
#
# The swapfile will alleviate out of memory issues during deployments,
# but should not be relied upon in cases of regular high memory use
# as it suffers from file-system and disk latency overheads.
#
# If swap is going to be used for performance reasons in use cases
# other than deployments, consider using a proper swap partition so
# file system overhead is not a factor
namespace :swapfile do
  set :path, '/swapfile'

  desc "Create the swapfile, if it does not yet exist"
  task :create do
    # Only create the swap file if it does not exist
    # (we especialy don't want to overwrite an existing swapfile)
    condition = "[ ! -f #{path} ]"

    # Write a 512MB swap file, chmod to 0600 and format it as a swap file
    command =
      "dd if=/dev/zero of=#{path} count=512k && "\
      "chmod 0600 #{path} && "\
      "mkswap #{path}"

    run "#{sudo} sh -c 'if #{condition}; then #{command}; fi'"
  end

  desc "Turn on the swapfile, if it is not yet on"
  task :enable do
    # Only turn on the swapfile if it is not
    # already on (included in the swapon -s list)
    condition = "! ( swapon -s | "\
      "cut -d \" \" -f 1 | "\
      "grep \"^#{path}$\" > /dev/null )"

    # Turn on the swap file
    command = "swapon #{path}"

    run "#{sudo} sh -c 'if #{condition}; then #{command}; fi'"\
  end

  desc "Create and enable the swapfile"
  task :setup do
    create
    enable
  end
  before "deploy:setup", "swapfile:setup"
end
