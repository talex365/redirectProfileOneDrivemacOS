#!/bin/sh

# This script is designed to be run through either self service or be run as part of enrollment
# This script is designed to move user home profile directories to the OneDrive
# sync folder, or if they're already in place, to set up the symlinks back to home
# Created by Jon Oregon 10/29/18

username="$3"
userHomePath="/Users/$username"
oneDriveDir='/Users/'$username'/OneDrive - yourOrgHere'
jamfOneDriveInstall="path to your self service OneDrive install here"


VerifyOneDrive()
{
	#Checks to see if OneDrive is already installed, if not prompts user to install
	#and opens installed in Self Service
	if ! open -Ra "/Applications/OneDrive.app"; then
		oneDriveInstalled=0
		jamf displayMessage -message "Please install and configure OneDrive"
		open 
	else
		oneDriveInstalled=1
	fi

	#waits for OneDrive to be installed, will exit after 10 minutes if not complete
	count=1
	while [ $oneDriveInstalled == 0 ]; do
		sleep 10
		let "count++"
		echo "holding on checking for app"
		echo $count
		if open -Ra "/Applications/OneDrive.app"; then
			oneDriveInstalled=1
		elif [ $count == 60 ]; then
			jamf displayMessage -message "Sorry, OneDrive did not complete installation, please contact IT"
			exit 1
		fi
	done

	#verifies OneDrive installed successfully, exits script with error if it's not present
	if ! open -Ra "/Applications/OneDrive.app"; then
		jamf displayMessage -message "Sorry, OneDrive did not complete installation, please contact IT"
		exit 1
	fi

	#Checks to see OneDrive sync folder has been created, if not opens OneDrive.app
	#and waits for user to configure, will exit script if dir doesn't exist after 10 minutes
	if [ ! -d "$oneDriveDir" ]; then
		open /Applications/OneDrive.app
		jamf displayMessage -message "Please set up your OneDrive sync folder"
		oneDriveDirExists=0
	else
		echo "OneDrive sync directory found at $oneDriveDir"
		oneDriveDirExists=1
	fi

	#waits for OneDrive sync folder to exist, will exit after 10 minutes if it isn't created
	count=1
	while [ $oneDriveDirExists == 0 ]; do
		sleep 10
		let "count++"
		echo "Holding for sync directory"
		echo $count
		if [ -d "$oneDriveDir" ]; then
			oneDriveDirExists=1
		elif [ $count == 60 ]; then
			jamf displayMessage -message "Sorry, OneDrive sync folder not detected, please contact IT"
			exit 1
		fi
	done
}

FinalCheck()
{
	#Check to see if profile folders already migrated (checks if directories are symlinks), exits if already moved
	if [ -L $userHomePath/Desktop -o -L $userHomePath/Documents -o -L $userHomePath/Pictures ]; then
		jamf displayMessage -message "Your profile appears to already have moved to OneDrive, please contact IT"
		echo "Profile already migrated, exiting migration"
		exit 1
	fi

	#Check to see if unsuccessful migration has occurred before
	if [ -f "$userHomePath/profileMove.log" ]; then
		echo "Previous migration failed, existing"
		jamf displayMessage -message "You have had a profile migration fail in the past, please contact IT"
		exit 1
	fi
}

MigrateFiles()
{
	#Moves folders from Home directory to OneDrive sync folder, creates symlinks
	if [ -d "$oneDriveDir" ]; then
		for i in Desktop Documents Pictures; do
			#If folder doesn't exist yet, will create
			if [ ! -d "$oneDriveDir/$i" ]; then
				mkdir "$oneDriveDir/$i"
			fi
			
			#Moves data from old home directory to new one, if data exists, moves to temp file and logs
			for d in "$userHomePath/$i/"*; do
				filename=$(basename "$d")
				if [ -d "$oneDriveDir/$i/$filename" -o -f "$oneDriveDir/$i/$filename" ]; then
					if [ ! -d "$userHomePath/Failed to Migrate" ]; then
						mkdir "$userHomePath/Failed to Migrate"
					fi
					echo "Unable to move file at /Users/$username/$i/$filename, file already exists, was moved to ~/Failed to Migrate/$i" >> "/Users/$username/Profile Migration.log"
					if [ ! -d "$userHomePath/Failed to Migrate/$i" ]; then
						mkdir "$userHomePath/Failed to Migrate/$i"
					fi
					mv "$d" "$userHomePath/Failed to Migrate/$i/"

				#Moves data to OneDrive
				else
					mv "$d" "$oneDriveDir/$i/"
				fi
			done
			
			#deletes original directory, sets up symlink
			rm -rf "$userHomePath/$i"
			ln -s "$oneDriveDir/$i" "$userHomePath"
		done
	fi
}

MigrationWrapup()
{
	if [ -d "$userHomePath/Failed to Migrate/" ]; then
		jamf displayMessage -message "Some files were not moved, please check Profile Migration.log at $userHomePath"
	fi

	#ensures user has full rights to new directories
	chown -R $username "$oneDriveDir/Desktop"
	chown -R $username "$oneDriveDir/Documents"
	chown -R $username "$oneDriveDir/Pictures"
	
	killall Finder
	
	echo "Profile Migration Complete"
	exit 0
}

VerifyOneDrive
FinalCheck
MigrateFiles
MigrationWrapup