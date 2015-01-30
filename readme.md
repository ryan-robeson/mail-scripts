# Mail Scripts
## My personal collection of scripts for managing emails.

This repo exists for my email scripts that don't deserve their own repos.
I'm a firm believer in letting computers work for me.
I've been wanting to script some email related activities for awhile.
We'll see how that goes...

## Details
### Download 7 Facts Submissions

This script's sole purpose for existing is to download homework submissions from my CSCI-1100 classes.
Saves me going through and clicking "Download" on ~50 emails.

#### Usage

Fill in creds.yaml with appropriate credentials.

`./download-7-facts-submissions.rb`

#### Side Effects

Creates:

* ./7facts/
    * 023/
        * attachment1
        * ...
    * 035/
        * attachment1
        * ...
    * 060/
        * attachment1
        * ...
    * unknown/
        * attachment1
        * ...
    * record.yaml

