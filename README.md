# Script tools for QAnalysts

## bug2.sh

This script was written to pull build information from a device or a folder containing a build.

### Usage:

```
Usage: ./bug2.sh [parameters]
   -d <build folder> Use a folder containing a build instead.
   -q		Automatically chooses default values when possible.
   -t   	Skips generating a bug template
   -v   	Show debug info about the script
```
----

## gg.sh

This script was created to make flashing builds a lot faster and simpler.

### Usage:

```
Usage: ./gg.sh <build_folder> <flash_file flag>
Flags:
gg : Use  flash_Gg.sh -dn          (Latest / Default)
de : Use  flash_Gg_de.sh -dn           (Latest with debug enabled)
ff : Use  fullflash_gecko_ril_gaia.sh -rn     (For older v1.3 and below)
tf : Use  flash_tarako.sh         (For Tarako devices)
nf : Use  naoki_flash.sh       (Fixes 'no space' error)
nx : Use  flash_Nexus_4.sh     (For Nexus 4)
```
### Note:

This script depends on other scripts existing in a specified folder. Their locations can be changed in the script. DO NOT USE SPACES IN THE PATH.


----

## debug_flags.sh

This script enables various debug flags for different situations that may not normally be available. 

### Usage:

```
Usage: ./debug_flags.sh
  -r	ril.debugging
  -m	mms.debugging
  -n	network.debugging
  -s	services.push.debug
```
### Note:

Other debug flags should be added to this script as they are discovered.


----

## logit.sh

Begins recording a logcat ( adb logcat -v threadtime ) saving it to a file ~/log/logcat_date_time_name.txt (log folder in the user's home directory) The < name > portion in the command is optional.
Automatically reconnects and resumes when connection with the device is lost. Also spawns a new window showing the current log. Much more lightweight than loading eclipse and it automatically saves all logs so nothing is ever lost. You should clean your log folder every now and then, though.

### Usage:

```
Usage: ./logit.sh <name>

```

----

## firewatch.sh

Logs memory usage on the device.
Exports to the ~/log folder like logit.sh.

### Usage:

```
Usage: ./firewatch.sh <name>
```

----

## logboth.sh

Runs both logit.sh and firewatch.sh. Basically a shortcut to running both scripts.

### Usage:

```
Usage: ./logboth <name>
```

----

## pull_crashlog.sh

Pulls crash logs from the device and generates a link to the crash database. This is significantly faster than using eclipse.

### Usage

```
Usage ./pull_crashlog.sh
```

----

## log_hcidump.sh

Logs Bluetooth activity and pushes the hcidump program to the device.
Exports to the ~/log folder like logit.sh.

### Usage:

```
Usage: ./log_hcidump <name>
```

----

## hasten_facebook_sync.sh

Changes the Facebook Sync period from 24 hours to 5 minutes for testing purposes.

### Usage:

```
Usage: ./hasten_facebook.sh
```

----

## genfile.sh

Generates a file of the specified size full of random garbage.


### Usage:

```
Usage: ./genfile.sh <size_in_mb> <filename>

Example: ./genfile.sh 10 ~/Desktop/file.txt will generate a 10mb file named 'file.txt' on the desktop. 
Directing to a drive and using a mb count higher than the drive's capacity will fill up the drive. 

WARNING: This program will not ask you twice! 
Linux will let you fill up your hard drive if you tell it to!

This will take some time depending on the size of the file being generated.
You can cancel the script by using ctrl + c
```

----

## bsplit.sh

Takes two builds and creates two new builds with the gaia and gecko swapped.

### Usage:

```
Usage: ./bsplit '/path/to/older/build/location/' '/path/to/newer/build/location/'

When this is run it will create a folder on the desktop called gecko_gaia_split with 
two more folders called:
Last_Working_Gaia_First_Broken_Gecko
First_Broken_Gaia_Last_Working_Gecko

```
----


