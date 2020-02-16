



## To Use

To clone and run this repository you'll need [Git](https://git-scm.com) and [Node.js](https://nodejs.org/en/download/) (which comes with [npm](http://npmjs.com)) installed on your computer. From your command line:

```bash
# Clone this repository
git clone https://github.com/electron/pipecraft-quick-start
# Go into the repository
cd pipecraft-quick-start
# Install dependencies
npm install
# Run the app
npm start
```

## To Build
Install electron-packager. This module requires Node.js 8.0 or higher to run.On Windows, both .NET Framework 4.5 or higher and Powershell 3 or higher are required. For use in npm scripts (recommended) npm install electron-packager --save-dev
Check electron module version in the devDependencies section of package.json, and set it the exact version of 1.4.15.

```bash
npm install electron-packager -g
electron-packager .
```

## Git

When pulling from a remote upstream, git fetch --all did the trick for me:

```bash
git remote add upstream https://github.com/SuvalineVana/pipecraft-quick-start
git checkout master
git fetch --all
git merge upstream/master
```

When updating the master branch

```bash
git add .
git commit -m "commit message"
git remote add origin https://github.com/SuvalineVana/pipecraft-quick-start.git
git push -u origin master
```
## Dockerhub

Pull image
```bash
docker pull metsoja/pipecraft:latest
```

To push a new tag to this repository
```bash
docker push metsoja/pipecraft:tagname
```

## Docker

Pull image
```bash
docker pull metsoja/pipecraft:latest
```

To push a new tag to this repository
```bash
docker push metsoja/pipecraft:tagname
```

For container modifications via bash
```bash
docker run --interactive --tty pipecraft:alfa bash
```

For analysis testing
```bash
docker run --interactive --tty  -v C:\Users\m_4_r\Desktop\Docker\electron-quick-start:/destination  pipecraft:alfa bash
```

For build
```bash
docker build -t pipecraft:alfa -f .\Dockerfile .  
```

Remove all containers
```bash
docker rm `docker ps -a -q`
```

Remove all “Exited” containers:
```bash
docker rm $(docker ps -a | grep 'Exited' | awk '{print $1}')
```

Remove all images matching a name:
```bash
docker rmi $(docker images | grep MYNAME_ | awk '{print $3}')
```


## License

[CC0 1.0 (Public Domain)](LICENSE.md)
