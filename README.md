# K8s Secret Script

This is just a simple script which helps the user create a Kubernetes secret one key-value pair at a time, and provides the ability to automatically generate a variable-length random string as a value if desired.

### Usage

Run the script like any other shell script

    ./rand-secret.sh

The script will guide you through the process of selecting your secret's name, namespace (defaults to the current kubectl config context default), and key-value pairs. Type `?` for a value to select a random string and it will ask for how long you'd like it to be. The default is 24 characters.
