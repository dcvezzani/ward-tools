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

const doNotContact = JSON.parse(fs.readFileSync('./do-not-contact.json').toString()).filter(entry => Object.keys(entry).length > 0)
const doNotContactNames = doNotContact.map(entry => entry.name)

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
          // if (entry.name.match(/Vezzani/)) console.log(">>>entry", entry)
          const {name, phone, email, address, district, neighborhood} = entry
          const members = entry.members.map(member => {
            const {name, sex, birthDate} = member
            return {name, sex, birthDate}
          })
          coll[entry.name] = { name, phone, email, address, district, neighborhood, members }

          entry.members.forEach(fmember => {
          // console.log(">>>fmember", fmember)
            coll[fmember.name] = { phone, email, address, ...fmember, district, neighborhood }
          })
          return coll
        }, {})
        // console.log(">>>data.directory", data.directory);
        // console.log(">>>me", data.directory["Vezzani, David Curtis"])
        
        cb()
      },
      eq: (cb) => {
        // console.log(">>>trace 2", data.directory)
        fs.readFile('./eq-cleaned.json', (err, content) => {
          if (err) return cb(err)
          data.eq = JSON.parse(content).filter(entry => !doNotContactNames.includes(entry.name)).map(entry => {
            // console.log(">>>entry", entry.name)
            const directoryEntry = data.directory[entry.name]
            // console.log(">>>directoryEntry", directoryEntry)
            const {uuid, givenName, surname, phone, email, address, district, neighborhood} = directoryEntry;
            return {...entry, uuid, givenName, surname, phone, email, address, district, neighborhood}
          })
          // console.log(">>>data.eq", data.eq)
          data.available_brothers = JSON.parse(JSON.stringify(data.eq))
          cb()
        });
      },
      ym: (cb) => {
        fs.readFile('./ym-cleaned.json', (err, content) => {
          if (err) return cb(err)
          data.ym = JSON.parse(content).filter(entry => !doNotContactNames.includes(entry.name)).map(entry => {
            const directoryEntry = data.directory[entry.name]
            const {uuid, givenName, surname, phone, email, address, district, neighborhood} = directoryEntry;
            return {...entry, uuid, givenName, surname, phone, email, address, district, neighborhood}
          })
          // console.log(">>>data.ym", data.ym)
          data.available_brothers = [...data.available_brothers, ...(JSON.parse(JSON.stringify(data.ym)))]
          cb()
        });
      },
      // ignore_members: (cb) => {
      //   fs.readFile('./ignore.json', (err, content) => {
      //     if (err) return cb(err)
      //     data.ignore = JSON.parse(content);
      //     data.ignore_names = data.ignore.map(brother => brother.name)
      //     // console.log(">>>data.ignore_names", JSON.stringify(data.ignore_names, null, 2))
      //     data.ignore_families = data.ignore.map(family => family.uuid)
      //     // console.log(">>>data.ignore_families", JSON.stringify(data.ignore_families, null, 2))

      //     // remove ignored ministering brothers
      //     data.available_brothers = data.available_brothers.filter(brother => !data.ignore_names.includes(brother.name))
          
      //     // remove ignored families
      //     data.available_families = data.available_families.filter(family => {
      //       // if (family.uuid === '224f6b10-9880-4bfc-8cf0-79d725315d0c')
      //       // console.log(">>>family.uuid", family.uuid)

      //       return family.members.reduce((res, member) => {
      //         res = (!data.ignore_families.includes(member.uuid) && res)
      //         return res
      //       }, true)
      //     })
      //     cb()
      //   });
      // },
      available_eq: (cb) => {
        const filtered_eq = data.available_brothers //.filter(brother => !data.ignore_names.includes(brother.name))
        data.available_brothers = filtered_eq
        fs.writeFile('available_eq.json', JSON.stringify(filtered_eq), (err) => {
          if (err) return cb(err)
          console.log('The file (available_eq.json) has been saved!');
          cb()
        });
      },
      current_assignments: (cb) => {
        fs.readFile('./ministering-eq.json', (err, content) => {
          if (err) return cb(err)
          data.current_assignments = JSON.parse(content)
          data.current_assignments = data.current_assignments.props.pageProps.initialState.ministeringData.elders
          // console.log(">>>data.current_assignments", data.current_assignments)
          // console.log(">>>data.current_assignments", data.current_assignments.map(entry => entry.companionships.map(comp => data.directory[comp.ministers[0].name])))
          // console.log(">>>data.current_assignments", data.current_assignments.map(entry => entry.companionships.map(comp => comp.assignments[0])))
          // console.log(">>>matthew", data.directory["Vezzani, Matthew"])
          // console.log(">>>me", data.directory["Vezzani, David Curtis"])
          // console.log(">>>data.current_assignments", data.current_assignments.map(entry => entry.companionships[0]))

          // district name and supervisor; need preferred name, phone, email
          // console.log(">>>data.current_assignments", data.current_assignments[0])

          // ministers and assignments; need preferred name, phone, address, email
          // assignments; need last name, gender, birth date without year


          const chk = data.current_assignments.map(district => {
            const { districtName, supervisorName } = district;
            // console.log(">>>districtName, supervisorName", { districtName, supervisorName })
            if (!supervisorName) return { districtName, supervisor: {}, companionships: [] }
            const {phone, email, address, name} = data.directory[supervisorName]

            const companionships = (district.companionships || []).map((companionship, companionshipId) => {
              // const ministers = companionship.ministers.map(minister => {
              //   const {phone, email, address, name} = {phone: '', email: '', address: '', ...data.directory[minister.name]}
              //   return {phone, email, address, name}
              // })
              // console.log(">>>companionship", companionship)

              let ministers = []
              if (companionship.ministers.length > 0) {
                ministers = companionship.ministers.map(minister => {
                  const {phone, email, address, name} = {phone: '', email: '', address: '', ...data.directory[minister.name]}
                  return {phone, email, address, name, companionshipId: (companionshipId+1)}
                })
              } else {
                // console.log(">>>companionship.ministers", companionship.ministers)
              }

              if (!companionship.assignments) companionship.assignments = []
              const assignments = companionship.assignments.map(assignment => {
                const {phone, email, address, name, members} = {phone: '', email: '', address: '',  ...data.directory[assignment.name]}
// if (assignment.name.match(/Vezzani/)) console.log(">>>assignment, vezzani", members)
// if (assignment.name.match(/Vezzani/)) console.log(">>>assignment, vezzani", data.directory[assignment.name])
// if (assignment.name.match(/Vezzani/)) console.log(">>>assignment, vezzani", {phone, email, address, name, members})
// if (assignment.name.match(/Geddes/)) console.log(">>>assignment, vezzani", {phone, email, address, name, members})
                return {phone, email, address, name, members}
              })
              return {ministers, assignments};
            })

            return { districtName, supervisor: {phone, email, address, name}, companionships }

          })
          // console.log(">>>me", data.directory["Vezzani, David Curtis"])
          // console.log(">>>chk", chk)
 
        fs.writeFile('ministering-assignments-print-out.json', JSON.stringify(chk), (err) => {
          if (err) throw err;
          console.log('The file (ministering-assignments-print-out.json) has been saved!');
          cb()
        });
          
          // cb()
        });
      },
      assigned_brothers: (cb) => {
        fs.readFile('./ministering-brothers.json', (err, content) => {
          if (err) return cb(err)
          data.assigned_brothers = JSON.parse(content).filter(brother => brother.hasCompanion === 1)
          // console.log(">>>data.assigned_brothers", data.assigned_brothers.find(brother => brother.name.startsWith('Ash')))
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
        console.log(">>>available_brothers_names", available_brothers_names.length);
        const assigned_brothers_names = data.assigned_brothers.map(brother => brother.name)
        console.log(">>>assigned_brothers_names", assigned_brothers_names.length);

        const unassigned_brothers_names = available_brothers_names.filter(brother => !assigned_brothers_names.includes(brother))
        console.log(">>>unassigned_brothers_names", unassigned_brothers_names.length);

        console.log(">>>doNotContactNames", doNotContactNames)
        data.unassigned_brothers = data.available_brothers.filter(entry => !doNotContactNames.includes(entry.name)).filter(brother => unassigned_brothers_names.includes(brother.name))
        console.log(">>>data.unassigned_brothers", data.unassigned_brothers.length);

        cb()
      },
      unassigned_families: (cb) => {
        // console.log(">>>data.available_families", data.available_families);
        const available_families_names = data.available_families.filter(entry => !doNotContactNames.includes(entry.name)).map(family => family.name)
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
          console.log('The file (report.json) has been saved!');
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
