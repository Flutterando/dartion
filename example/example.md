# Dartion - Usage Example

## Initiate Dartion

**Init server**:

Execute this command in an empty folder:

```
dartion init
```

This will create the files you can see in the Example folder.
The `config.yaml` is the file you want to change so you can add your own configurations. 

**Start server**:

This command will boot the server based on the settings in `config.yaml`.

```
dartion serve
```

Remember to use it in the folder with the files you wish to use. 
If you start it using the Example folder you can run the Dartion tests for example. 

**Changing data**:

The file `db.json` can be changed to add your own data to your mock server.