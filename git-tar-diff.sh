#!/bin/bash
export LC_ALL=fr_FR.utf8
### WARNING: this script won't work if there are too many changes

# Increase max si of arguments
ulimit -s 65536

fromRef=""
toRef=""
pretend=""
verbose=""
openExplorer=""
copyDeleted=""

if [[ $# = 0 ]] ; then
    extract="1"
    rm="1"
fi

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -h|--help) 
        echo "Generates a tar archive off all differences between two commits" 
        echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" 
        echo "Usage" 
        echo "~~~~~~" 
        echo "Generate a tar archive off all differences between HEAD and <ref_to>" 
        echo "    deploy.sh <ref_to>"
        echo ""
        echo "Generate a tar archive off all differences between <ref_from> and <ref_to>" 
        echo "    deploy.sh <ref_from> <ref_to>"
        echo ""
        echo "Options"
        echo "    -f|--ftp: Display the FTP command to remove deleted files"
        echo "    -e: Open the update folder in the explorer"
        echo "    -fc|--clip-ftp: Copy the FTP command to remove deleted files to the clipboard"
        echo "    -h|--help: Display this help"
        echo "    --ssh: Display SSH command to untar archive and unlink deleted files"
        echo "    -p|--pretend: Don't create the actual archive and display a summary of all differences"
        echo "    -x|--extract: Extract the generated archive to an 'update' directory."
        echo "    -xr|--extract-rm: Extract the generated archive to an 'update' directory then delete the generated archive."
        echo "    -xre: Extract the generated archive to an 'update' directory, delete the generated archive, display the deleted files and open the folder with changed files."
        echo "    -xred: Extract the generated archive to an 'update' directory, delete the generated archive, clip the deleted files and open the folder with changed files."
        echo "    -s|--staged: Compares HEAD with staging area."
        echo "    -v|--verbose: Display changed files list"
        exit 0 ;;

        -f|--ftp) ftp="1"; shift ;;
        -fc|--clip-ftp) ftpClip="1"; ftp="1"; shift ;;
        -x|--extract) extract="1"; shift ;;
        -xr|--extract-rm) extract="1"; rm="1"; shift ;;
        -xre) extract="1"; rm="1"; openExplorer="1"; shift ;;
        -xred) extract="1"; rm="1"; openExplorer="1"; copyDeleted="1" ; shift ;;
        -uc|--clip-untar) untarClip="1"; shift ;;
        -e) openExplorer="1"; shift ;;
        -d) copyDeleted="1"; shift ;;
        -v|--verbose) verbose="1"; shift ;;
        -p|--pretend) pretend="1"; verbose="1"; shift ;;
        --ssh) ssh="1"; shift ;;
        -s|--staged) stagingArea="1"; shift ;;
        -xs) extract="1"; stagingArea="1"; shift ;;
        -xrs|-srx|-xrs|-sxr) extract="1"; rm="1"; stagingArea="1"; shift ;;
        -xres|-xres|-sxre) extract="1"; rm="1"; stagingArea="1"; openExplorer="1"; shift ;;

        -*) echo "unknown option: $1" >&2; exit 1;;

        *)
         if [[ $fromRef = "" ]] ; then
            fromRef="$1"
         else
            echo "Too many arguments" >&2; exit 1
         fi
         shift ;;
    esac
done

if [[ $stagingArea = "1" ]] ; then
    fromRef="--staged"
elif [[ $fromRef = "" ]] ; then
    fromRef="HEAD^1"
fi

toRef="HEAD"

# Create a tar archive of all modified files
if [[ $pretend = "" ]] ; then
    upsertedFiles="$(git diff --name-only "$fromRef" --diff-filter d)"
    chunkSizes="$(echo "$upsertedFiles" | wc -l)"

    # Deal with the Too many argument error when creating the archive
    if [ "$chunkSizes" -gt 500 ]; then
        filesChunks=()
        counter=0
        archivesCount=0
        archives=()
        while IFS= read -r file; do
            filesChunks+=("$file")
            counter=$((counter + 1))

            # Create archives with 500 files
            if [ "$counter" -eq 500 ]; then
                archives+=("update_$archivesCount.tar")
                git archive --format=tar --output="update_$archivesCount.tar" HEAD "${filesChunks[@]}"

                archivesCount=$((archivesCount + 1))

                counter=0
                filesChunks=()
            fi
        done <<< "$upsertedFiles"

        # Create archives with resulting files
        if [ "$counter" -gt 0 ]; then
            archives+=("update_$archivesCount.tar")
            git archive --format=tar --output="update_$archivesCount.tar" HEAD "${filesChunks[@]}"
        fi

        rm -f update.tar
        tar -cf update.tar --files-from /dev/null

        for archive in "${archives[@]}"; do
            tar -Af update.tar "$archive"
        done

        rm -f "${archives[@]}"
    else
        git archive --format=tar --output=update.tar HEAD $upsertedFiles
    fi
fi

# Get moved and deleted files lit
deletedFiles="$(git diff "$fromRef" "$toRef" --name-status --diff-filter=D --no-renames | grep -Po "(\S+)$" | paste -s -d' ' -)"
rmCmd="rm -f "$deletedFiles""
ftpDeleCmd="DELE "$deletedFiles""
finalCmd="tar xzf update.tar -o && tar ztf update.tar | xargs chown 10026:1003"

# Prepare rm command
if [[ $rmCmd != "rm -f  " ]] ; then
    theCmd="$rmCmd && $finalCmd"
else
    theCmd=$finalCmd
fi

changedFiles="$(git diff "$fromRef" "$toRef" --name-only --diff-filter=d --no-renames)"
deletedFiles="$(echo "$deletedFiles" | sed 's/ *$//g')"

echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" 

if [[ $pretend = "" ]] ; then
    echo "update.tar archive of differences between "$fromRef" and "$toRef" generated!"
else
    echo "Pretend mode, no tar archive generated!"
fi

if [[ $ftpClip = "1" ]] ; then
    echo $ftpDeleCmd | clip
    echo "FTP command copied to clipboard: "$ftpDeleCmd""
elif [[ $ftp = "1" ]] ; then
    echo "FTP command"
    echo "    "$ftpDeleCmd""
    echo ""
fi

if [[ $ssh = "1" ]] ; then
    echo "SSH command"
    echo "    $theCmd"
    echo ""
fi

if [[ $verbose = "1" ]] ; then
    echo "Added and changed files:"
    echo ""
    echo $changedFiles
    echo ""
    echo ""
    echo "Deleted files:"
    echo ""
    echo $deletedFiles
fi

untarCommand="tar -xf update.tar --directory update"

if [[ $untarClip = "1" ]] ; then
    echo $untarCommand | clip
    echo "untar command copied to clipboard: "$untarCommand""
fi

if [[ $extract = "1" ]] ; then
    rm -rf update/
    mkdir update
    tar -xf update.tar --directory update
    echo "Differences copied to the update folder."

    if [[ $openExplorer = "1" ]] ; then
        explorer update
    fi
fi

if [[ $verbose = "" ]] ; then
    if [[ $deletedFiles != "" ]] ; then
        if [[ $copyDeleted = "1" ]] ; then
            echo "rm -f $deletedFiles" | clip
            echo "rm command copied to clipboard."
        else
            echo "The following files must be deleted files:"
            echo ""
            echo "$deletedFiles"
        fi
    fi
fi

if [[ $rm = "1" ]] ; then
    rm update.tar
fi

