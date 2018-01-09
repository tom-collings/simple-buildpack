# simple-buildpack
A simple buildpack for multi-buildpack testing.

This buildpack simply adds a file through the `supply` script to the /app directory.  This can be verified via a `cf ssh` to the app in question and navigating to that file.
