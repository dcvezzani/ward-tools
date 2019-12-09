const fs = require('fs');
const readline = require('readline');
const {google} = require('googleapis');
const PROJECT_DIR = '..'

// If modifying these scopes, delete token.json.

// const credentialsFile = `${PROJECT_DIR}/credentials.json`;
// const SCOPES = ['https://www.googleapis.com/auth/documents.readonly'];
//
const credentialsFile = `./client_secret_759165666012-n6sqf23nj0lm2143sin7jkettrsqu2ue.apps.googleusercontent.com.json`
const SCOPES = ['https://www.googleapis.com/auth/drive.file'];

// https://www.googleapis.com/auth/documents.readonly
// https://www.googleapis.com/auth/drive
// https://www.googleapis.com/auth/drive.appdata
// https://www.googleapis.com/auth/drive.file

// The file token.json stores the user's access and refresh tokens, and is
// created automatically when the authorization flow completes for the first
// time.
const TOKEN_PATH = `${PROJECT_DIR}/token.json`;

// Load client secrets from a local file.
fs.readFile(credentialsFile, (err, content) => {
  if (err) return console.log('Error loading client secret file:', err);
  // Authorize a client with credentials, then call the Google Docs API.
  // authorize(JSON.parse(content), printDocTitle);
  // authorize(JSON.parse(content), uploadFile);
  authorize(JSON.parse(content), updateFile);
});

/**
 * Create an OAuth2 client with the given credentials, and then execute the
 * given callback function.
 * @param {Object} credentials The authorization client credentials.
 * @param {function} callback The callback to call with the authorized client.
 */
function authorize(credentials, callback) {
  const {client_secret, client_id, redirect_uris} = credentials.installed;
  const oAuth2Client = new google.auth.OAuth2(
      client_id, client_secret, redirect_uris[0]);

  // Check if we have previously stored a token.
  fs.readFile(TOKEN_PATH, (err, token) => {
    if (err) return getNewToken(oAuth2Client, callback);
    oAuth2Client.setCredentials(JSON.parse(token));
    callback(oAuth2Client);
  });
}

/**
 * Get and store new token after prompting for user authorization, and then
 * execute the given callback with the authorized OAuth2 client.
 * @param {google.auth.OAuth2} oAuth2Client The OAuth2 client to get token for.
 * @param {getEventsCallback} callback The callback for the authorized client.
 */
function getNewToken(oAuth2Client, callback) {
  const authUrl = oAuth2Client.generateAuthUrl({
    access_type: 'offline',
    scope: SCOPES,
  });
  console.log('Authorize this app by visiting this url:', authUrl);
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout,
  });
  rl.question('Enter the code from that page here: ', (code) => {
    rl.close();
    oAuth2Client.getToken(code, (err, token) => {
      if (err) return console.error('Error retrieving access token', err);
      oAuth2Client.setCredentials(token);
      // Store the token to disk for later program executions
      fs.writeFile(TOKEN_PATH, JSON.stringify(token), (err) => {
        if (err) console.error(err);
        console.log('Token stored to', TOKEN_PATH);
      });
      callback(oAuth2Client);
    });
  });
}

/**
 * Prints the title of a sample doc:
 * https://docs.google.com/document/d/195j9eDD3ccgjQRttHhJPymLJUCOUjs-jmwTrekvdjFE/edit
 * @param {google.auth.OAuth2} auth The authenticated Google OAuth 2.0 client.
 */
function printDocTitle(auth) {
  const docs = google.docs({version: 'v1', auth});
  docs.documents.get({
    documentId: '11a2bvDVooOboVP1J6pL0PAIAB2EeYaO4kqJhBTn2Ryk',
  }, (err, res) => {
    if (err) return console.log('The API returned an error: ' + err);
    console.log(`The title of the document is: ${res.data.title}`);
  });
}

function uploadFile(auth) {
  const drive = google.drive({version: 'v3', auth});

  var fileMetadata = {
    'name': 'elders-in-aux.html',
    mimeType: 'application/vnd.google-apps.document'
  };
  var media = {
    mimeType: 'text/html',
    body: fs.createReadStream('elders-in-aux.html')
  };
  drive.files.create({
    resource: fileMetadata,
    media: media,
    fields: 'id'
  }, function (err, file) {
    if (err) {
      // Handle error
      console.error(err);
    } else {
      console.log('File Id: ', file);
    }
  });
}

function updateFile(auth) { 
  const drive = google.drive({version: 'v3', auth});

  var fileMetadata = {
    'name': 'elders-in-aux.html',
    mimeType: 'application/vnd.google-apps.document'
  };
  var media = {
    mimeType: 'text/html',
    body: fs.createReadStream('elders-in-aux.html')
  };
  drive.files.update({
    fileId: '15xsK8gn3mBPIKLDrwrSupxZdbgUEaChfFBBTOOrXr5E',
    media: media,
    fields: 'id'
  }, function (err, file) {
    if (err) {
      // Handle error
      console.error(err);
    } else {
      console.log('File Id: ', file);
    }
  });
}

