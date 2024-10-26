# hw-env-docker


## Run

Give `run.sh` executable permission:

Before running, make sure proxy settings are good for Docker access.


```bash
chmod +x run.sh
```

For usage, run:

```bash
./run.sh <command> [options]
```

Pull the base image, run:

```bash
./run.sh pull
```

Build the image, run:

```bash
./run.sh build -i hw-env
```

Run the container, run:

```bash
./run.sh run -i hw-env -c hw-env -v mount.json
```

The mount information is specified in `mount.json` in JSON format.

If you need proxy inside docker, put proxy settings in `Dockerfile.proxy`, and edit `Dockerfile` to include it (line 27).
