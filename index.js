import fs from 'fs'
import async from 'async'
import util from 'util'

const async_series = util.promisify(async.series);

const data = {
  directory: {}, 
  eq: {}, 
  ym: {}, 
  available_brothers: {}, 
  assigned_brothers: {}, 
  ministering_families: {}, 
}

const process = () => {
  return new Promise((resolve, reject) => {
    async.series({
      directory: (cb) => {
        fs.readFile('./directory.json', (err, content) => {
          if (err) return cb(err)
          // console.log(">>>trace 1.1", JSON.parse(content.toString()))
          data.available_families = JSON.parse(content.toString())
          data.directory = JSON.parse(content.toString())
          cb()
        });
      },
      reduceDirectory: (cb) => {
        data.directory = data.directory.reduce((coll, entry) => {
          console.log(">>>entry", entry)
          entry.members.forEach(fmember => {
            const {phone, email, address, district} = entry
            coll[fmember.name] = { ...fmember, phone, email, address, district }
          })
          return coll
        }, {})
        cb()
      },
      eq: (cb) => {
        // console.log(">>>trace 2", data.directory)
        fs.readFile('./eq-cleaned.json', (err, content) => {
          if (err) return cb(err)
          data.eq = JSON.parse(content).map(entry => {
            const directoryEntry = data.directory[entry.name]
            // console.log(">>>directoryEntry", directoryEntry)
            const {uuid, phone, email, address, district} = directoryEntry;
            return {...entry, uuid, phone, email, address, district}
          })
          // console.log(">>>data.eq", data.eq)
          data.available_brothers = JSON.parse(JSON.stringify(data.eq))
          cb()
        });
      },
      ym: (cb) => {
        fs.readFile('./ym-cleaned.json', (err, content) => {
          if (err) return cb(err)
          data.ym = JSON.parse(content).map(entry => {
            const directoryEntry = data.directory[entry.name]
            const {uuid, phone, email, address, district} = directoryEntry;
            return {...entry, uuid, phone, email, address, district}
          })
          // console.log(">>>data.ym", data.ym)
          data.available_brothers = [...data.available_brothers, ...(JSON.parse(JSON.stringify(data.ym)))]
          cb()
        });
      },
      assigned_brothers: (cb) => {
        fs.readFile('./ministering-brothers.json', (err, content) => {
          if (err) return cb(err)
          data.assigned_brothers = JSON.parse(content)
          // console.log(">>>data.assigned_brothers", data.assigned_brothers)
          cb()
        });
      },
      assigned_families: (cb) => {
        fs.readFile('./ministering-families.json', (err, content) => {
          if (err) return cb(err)
          data.assigned_families = JSON.parse(content)
          // console.log(">>>data.assigned_families", data.assigned_families)
          cb()
        });
      },
      unassigned_brothers: (cb) => {
        // console.log(">>>data.available_brothers", data.available_brothers);
        const available_brothers_names = data.available_brothers.map(brother => brother.name)
        const assigned_brothers_names = data.assigned_brothers.map(brother => brother.name)
        const unassigned_brothers_names = available_brothers_names.filter(brother => !assigned_brothers_names.includes(brother))
        // console.log(">>>unassigned_brothers", unassigned_brothers_names);

        data.unassigned_brothers = data.available_brothers.filter(brother => unassigned_brothers_names.includes(brother.name))
        // console.log(">>>data.unassigned_brothers", data.unassigned_brothers);

        cb()
      },
      unassigned_families: (cb) => {
        // console.log(">>>data.available_families", data.available_families);
        const available_families_names = data.available_families.map(family => family.name)
        const assigned_families_names = data.assigned_families.map(family => family.name)
        const unassigned_families_names = available_families_names.filter(family => !assigned_families_names.includes(family))
        // console.log(">>>unassigned_families_names", unassigned_families_names);

        data.unassigned_families = data.available_families.filter(family => unassigned_families_names.includes(family.name))
        // console.log(">>>data.unassigned_familys", data.unassigned_familys);

        cb()
      },
      by_districts: (cb) => {
        data.unassigned_brothers_by_district = data.unassigned_brothers.reduce((coll, brother) => {
          if (!coll[brother.district]) coll[brother.district] = []
          coll[brother.district].push(brother)
          return coll
        }, {})
        data.unassigned_families_by_district = data.unassigned_families.reduce((coll, family) => {
          if (!coll[family.district]) coll[family.district] = []
          coll[family.district].push(family)
          return coll
        }, {})
        cb()
      },
    }, 
      (err, res) => {
        // console.log(">>>brothers", {assigned: Object.keys(data.assigned_brothers).length, available: Object.keys(data.available_brothers).length});
        // console.log(">>>brothers", {assigned: Object.keys(data.assigned_brothers).length, available: Object.keys(data.available_brothers).length, unassigned: Object.keys(data.unassigned_brothers).length});
        // console.log(">>>data.unassigned_brothers_by_district", data.unassigned_brothers_by_district);

        const report = {ministering_brothers: {assigned: Object.keys(data.assigned_brothers).length, available: Object.keys(data.available_brothers).length, unassigned: Object.keys(data.unassigned_brothers).length, by_district: data.unassigned_brothers_by_district}, ministering_families: {assigned: Object.keys(data.assigned_families).length, available: Object.keys(data.available_families).length, unassigned: Object.keys(data.unassigned_families).length, by_district: data.unassigned_families_by_district}}
        // const report = {ministering_brothers: {assigned: Object.keys(data.assigned_brothers).length, available: Object.keys(data.available_brothers).length, unassigned: Object.keys(data.unassigned_brothers).length}, ministering_families: {assigned: Object.keys(data.assigned_families).length, available: Object.keys(data.available_families).length, unassigned: Object.keys(data.unassigned_families).length}}
 
        // console.log(">>>report", report);
        
        fs.writeFile('report.json', JSON.stringify(report), (err) => {
          if (err) throw err;
          console.log('The file has been saved!');
          resolve()
        });
    })
  })
}

const main = async () => {
    await process()
    // console.log(">>>done");
    // console.log(name); // the console writes "John Doe" after 3000 milliseconds

}

main()
