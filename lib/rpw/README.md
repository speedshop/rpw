## Installation Requirements

This client assumes you're using Ruby 2.3 or later.

This client assumes you have `tar` installed and available on your PATH.

The way that the client opens files (using `open` or `xdg-open` depending on platform) assumes you have your default program for the following filetypes set correctly:

* .md for Markdown (XCode by default on Mac: you probably want to change that!)
* .mp4 for videos

## Slack Invite 

If you purchased the Workshop yourself, you will receive a Slack channel invitation
shortly. If you are attending the Workshop as part of a group and your license key
was provided to you, you need to register your key to get an invite:

```
$ rpw key register [YOUR_EMAIL_ADDRESS]
```

Please note you can only register your key once.

The Slack channel is your best resource for questions about Rails Performance
or other material in the workshop. Nate is almost always monitoring that channel.

If you encounter a **bug or other software problem**, please email support@speedshop.co.

## Important Commands

Here are some important commands for you to know:

```
$ rpw lesson next     | Proceed to the next part of the workshop.
$ rpw lesson complete | Mark current lesson as complete.
$ rpw lesson list     | List all workshop lessons. Note each lesson is preceded with an ID.
$ rpw lesson download | Download all lessons. Useful for offline access.
$ rpw lesson show     | Show any particular workshop lesson.
$ rpw progress        | Show where you're currently at in the workshop.
```

Generally, you'll just be doing a lot of `$ rpw lesson next`!

By default, `$ rpw lesson next` will try to open the content it downloads. If you 
either don't like this, or for some reason it doesn't work, use `$ rpw lesson next --no-open`.

## Working Offline 

By default, the course will download each piece of content as you progress through 
the course. However, you can use `rpw lesson download all` to download all content
at once, and complete the workshop entirely offline.

Videos in this workshop are generally about 100MB each, which means the entire
course is about a 3 to 4GB download.

## Bugs and Support

If you encounter any problems, please email support@speedshop.co for the fastest possible response.