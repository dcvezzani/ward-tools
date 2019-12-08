# ministering

## Project setup
```
yarn install
```

### Compiles and hot-reloads for development
```
yarn run serve
```

### Compiles and minifies for production
```
yarn run build
```

### Run your tests
```
yarn run test
```

### Lints and fixes files
```
yarn run lint
```

### Run your end-to-end tests
```
yarn run test:e2e
```

### Run your unit tests
```
yarn run test:unit
```

Select '<District>' in Vue Dev tools

```
$vm0.selectedNameIds = [264, 174, 475, 34, 370, 359, 129, 95, 273, 252, 529]

volunteers = $vm0.names.filter(name => $vm0.selectedNameIds.includes(name.id)).map(name => ({district: name.district, name: name.name, email: name.email, phone: name.phone }))

report = volunteers.reduce((coll, v) => {
  coll.push(Object.values(v).join("; "))
  return coll
}, [])

JSON.stringify(report)
```

Copy from Chrome console.  Paste in terminal.

```
echo '["03; Blair, Gary; gary.blair54@gmail.com; 801-232-0079","02; Densley, Logan; Logandensley@hotmail.com; 801-367-6544","03; Fieldsted, Mack; mfieldsted@yahoo.com; 8016553659","01; Gualotuna Guanuna, Edwin Oswaldo; edwingualotuna5@gmail.com; 801-636-7973","02; Jones, Ben; senojneb@yahoo.com; 801-310-4568","01; Konold, Doyle Eric; doyle.konold@aggiemail.usu.edu; 435-406-4069","02; Lattin, Peter; petelattin@gmail.com; 801-830-7957","03; Owen, Jason; jasonowen6@gmail.com; 8013699268","02; Pennington, Bridger; bridgerpennington@gmail.com; 8016748413","01; Taylor, Jack; jack.taylor@me.com; 801-473-5771","02; Williams, Brandon; brandon.wms@gmail.com; 661-313-6747"]' | jq -r '. | join("\n")' | column -t -s';' | pbcopy
```

Example of final report.  Pasted in email.  Set font to fixed width or Courier.

```
d#   name                               phone
==   ====                               =====
01   Gualotuna Guanuna, Edwin Oswaldo   801-636-7973
01   Konold, Doyle Eric                 435-406-4069
01   Taylor, Jack                       801-473-5771

02   Densley, Logan                     801-367-6544
02   Jones, Ben                         801-310-4568
02   Lattin, Peter                      801-830-7957
02   Pennington, Bridger                8016748413
02   Williams, Brandon                  661-313-6747

03   Blair, Gary                        801-232-0079
03   Fieldsted, Mack                    8016553659
03   Owen, Jason                        8013699268
```



