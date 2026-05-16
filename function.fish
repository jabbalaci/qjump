# Copy this file to the folder `~/.config/fish/functions`
# and rename it to `qj.fish` .
# Don't forget to set the path to `qjump` (`QJ` variable).
# Then, open a new terminal and issue the command `qj`,
# which will actually call this function.

function qj -d "QJump script"
    set -l QJ "/home/jabba/Dropbox/nim/_projects/qjump/qjump"
    if test -z $argv[1]
        $QJ
    else
        cd ($QJ $argv[1])
    end
end
