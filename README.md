```
source ../kaiser/mystic_rose/namespaces/production/env.sh
NODE_ENV=production npm run dist
source ~/.bashrc
```

packages are shared with fam (node_modules `ln -s ../fam/node_modules/ ./node_modules`)
so any new packages this requires have to go in fam too

otherwise webpack duplicates all node modules to make bundle huge
