import {readFileSync} from 'node:fs';
import {after, before, beforeEach, test} from 'node:test';
import {initializeTestEnvironment, assertFails, assertSucceeds} from '@firebase/rules-unit-testing';
import {doc, collection, collectionGroup, query, orderBy, startAt, endAt, documentId, getDoc, getDocs, setDoc, updateDoc, deleteDoc, Timestamp, serverTimestamp} from 'firebase/firestore';

test('persistent deletion marker blocks all family writes and is private',async () => {
  const family={createdAt:stamp(),updatedAt:stamp(),locale:'tr'};
  const profile={nickname:'Deniz',avatarId:'cat',ageRange:'4-6',survey:{},settings:{},createdAt:stamp(),updatedAt:stamp()};
  const progress={themeId:'animals',modeId:'G01',difficulty:'easy',stages:5,independent:3,maxHint:4,updatedAt:stamp()};
  const stats={correct:3,wrong:1,hintCounts:[0,1,2,0,0],updatedAt:stamp()};
  const writes=[['families/alice',family],['families/alice/profiles/profile-1',profile],['families/alice/profiles/profile-1/progress/animals-G01-easy',progress],['families/alice/profiles/profile-1/itemStats/cat',stats],[path,summary()]];
  for(const [target,payload] of writes) await assertSucceeds(setDoc(doc(db('alice'),target),payload));
  await env.withSecurityRulesDisabled(async context => {
    await setDoc(doc(context.firestore(),'deletionLocks/alice'),{status:'pending',createdAt:stamp(),updatedAt:stamp()});
    await setDoc(doc(context.firestore(),'admins/admin'),{enabled:true});
  });
  for(const [target,payload] of writes) {
    await assertFails(setDoc(doc(db('alice'),target),payload));
    await assertSucceeds(getDoc(doc(db('alice'),target)));
    await assertSucceeds(deleteDoc(doc(db('alice'),target)));
    await assertFails(setDoc(doc(db('alice'),target),payload));
  }
  for(const uid of ['alice','bob','admin',null]) {
    const lock=doc(db(uid),'deletionLocks/alice');
    await assertFails(getDoc(lock));
    await assertFails(setDoc(lock,{status:'complete',createdAt:stamp(),updatedAt:stamp()}));
    await assertFails(deleteDoc(lock));
  }
  // Completion preserves the marker: an old valid token still cannot recreate.
  await env.withSecurityRulesDisabled(async context => updateDoc(doc(context.firestore(),'deletionLocks/alice'),{status:'complete'}));
  await assertFails(setDoc(doc(db('alice'),path),summary()));
  await assertSucceeds(setDoc(doc(db('bob'),path.replace('alice','bob')),summary()));
});

const projectId = 'demo-special-education-rules';
let env;
const stamp = () => Timestamp.fromMillis(Date.now() - 60000);
const id = '2026-10-15_animals_G01_easy';
const path = `families/alice/profiles/profile-1/sessions/${id}`;
const summary = () => ({date:'2026-10-15',themeId:'animals',modeId:'G01',difficulty:'easy',activeMs:60000,rounds:1,stages:5,independent:3,updatedAt:stamp()});
const db = uid => uid ? env.authenticatedContext(uid).firestore() : env.unauthenticatedContext().firestore();
before(async () => {
  env = await initializeTestEnvironment({projectId, firestore:{host:'127.0.0.1',port:8085,rules:readFileSync(new URL('../firestore.rules',import.meta.url),'utf8')}});
});
beforeEach(async () => env.clearFirestore());
after(async () => env?.cleanup());

test('owner can create/update/read/list/delete exact nine-field daily summaries',async () => {
  const ref = doc(db('alice'),path);
  await assertSucceeds(setDoc(ref,summary()));
  await assertSucceeds(updateDoc(ref,{activeMs:70000}));
  await assertSucceeds(getDoc(ref));
  await assertSucceeds(getDocs(collection(db('alice'),'families/alice/profiles/profile-1/sessions')));
  await assertSucceeds(deleteDoc(ref));
});
test('other accounts and anonymous clients cannot access family tree',async () => {
  await assertSucceeds(setDoc(doc(db('alice'),path),summary()));
  for(const uid of ['bob',null]) {
    await assertFails(getDoc(doc(db(uid),path)));
    await assertFails(getDocs(collection(db(uid),'families/alice/profiles/profile-1/sessions')));
    await assertFails(setDoc(doc(db(uid),path),summary()));
    await assertFails(updateDoc(doc(db(uid),path),{rounds:2}));
    await assertFails(deleteDoc(doc(db(uid),path)));
    await assertFails(getDoc(doc(db(uid),'families/alice')));
    await assertFails(getDoc(doc(db(uid),'families/alice/profiles/profile-1')));
  }
});
test('public config allows direct get only; only pre-provisioned admin writes',async () => {
  await env.withSecurityRulesDisabled(async context => {
    await setDoc(doc(context.firestore(),'config/app'),{freeGames:[]});
    await setDoc(doc(context.firestore(),'admins/admin'),{enabled:true});
  });
  for(const uid of ['alice',null]) {
    await assertSucceeds(getDoc(doc(db(uid),'config/app')));
    await assertFails(getDocs(collection(db(uid),'config')));
    await assertFails(setDoc(doc(db(uid),'config/app'),{freeGames:[]}));
  }
  await assertSucceeds(setDoc(doc(db('admin'),'config/app'),{freeGames:[]}));
  await assertSucceeds(getDoc(doc(db('admin'),'admins/admin')));
  await assertFails(setDoc(doc(db('alice'),'admins/alice'),{enabled:true}));
  await assertFails(getDocs(collection(db('admin'),'admins')));
});
test('one free trial per account: owner creates once with server time, never changes it',async () => {
  const own=doc(db('alice'),'trials/alice');
  await assertFails(setDoc(own,{startedAt:stamp()}));
  await assertFails(setDoc(own,{startedAt:serverTimestamp(),premium:true}));
  await assertFails(setDoc(doc(db('bob'),'trials/alice'),{startedAt:serverTimestamp()}));
  await assertFails(setDoc(doc(db(null),'trials/alice'),{startedAt:serverTimestamp()}));
  await assertSucceeds(setDoc(own,{startedAt:serverTimestamp()}));
  await assertSucceeds(getDoc(own));
  await assertFails(getDoc(doc(db('bob'),'trials/alice')));
  await assertFails(getDocs(collection(db('alice'),'trials')));
  await assertFails(setDoc(own,{startedAt:serverTimestamp()}));
  await assertFails(updateDoc(own,{startedAt:serverTimestamp()}));
  await assertFails(deleteDoc(own));
});

test('raw trials and premium storage are denied even to owner/admin',async () => {
  for(const uid of ['alice','admin',null]) {
    for(const denied of ['trials/t1','premium/status','families/alice/trials/t1','families/alice/premium/status','families/alice/profiles/profile-1/trials/t1']) {
      await assertFails(setDoc(doc(db(uid),denied),{premium:true}));
      await assertFails(getDoc(doc(db(uid),denied)));
    }
  }
  await assertFails(setDoc(doc(db('alice'),path),{...summary(),premium:true}));
  await assertFails(setDoc(doc(db('alice'),path),{...summary(),selectedIds:['cat']}));
});
test('all nine fields required and all counter types/nonnegative constraints enforced',async () => {
  for(const key of Object.keys(summary())) {
    const payload=summary(); delete payload[key];
    await assertFails(setDoc(doc(db('alice'),path),payload));
  }
  for(const key of ['activeMs','rounds','stages','independent']) {
    for(const value of [-1,1.5,true,'1',null]) await assertFails(setDoc(doc(db('alice'),path),{...summary(),[key]:value}));
  }
  await assertFails(setDoc(doc(db('alice'),path),{...summary(),independent:6}));
  for(const value of ['2026-10-15',null,Timestamp.fromMillis(0),Timestamp.fromMillis(Date.now()+3600000)]) {
    await assertFails(setDoc(doc(db('alice'),path),{...summary(),updatedAt:value}));
  }
});
test('invalid identifiers, difficulty, date and inconsistent document IDs are denied',async () => {
  for(const [key,values] of Object.entries({themeId:['','animal/slash','animal space'],modeId:['','G_01'],difficulty:['expert','EASY'],date:['yesterday','2026-13-01','2026-10-00','2026-02-30','2099-01-01']})) {
    for(const value of values) await assertFails(setDoc(doc(db('alice'),path),{...summary(),[key]:value}));
  }
  await assertFails(setDoc(doc(db('alice'),'families/alice/profiles/profile-1/sessions/wrong-id'),summary()));
  await assertFails(setDoc(doc(db('alice'),`families/alice/profiles/bad id/sessions/${id}`),summary()));
  // Match the document ID so calendar denial cannot pass via ID mismatch.
  for(const date of ['2026-02-30','2025-02-29','2099-01-01']) {
    await assertFails(setDoc(doc(db('alice'),`families/alice/profiles/profile-1/sessions/${date}_animals_G01_easy`),{...summary(),date}));
  }
  await assertSucceeds(setDoc(doc(db('alice'),'families/alice/profiles/profile-1/sessions/2024-02-29_animals_G01_easy'),{...summary(),date:'2024-02-29'}));
});
test('family/profile allowlists prevent top-level private logs or premium injection',async () => {
  const family={createdAt:stamp(),updatedAt:stamp(),locale:'tr'};
  await assertSucceeds(setDoc(doc(db('alice'),'families/alice'),family));
  for(const extra of ['premium','trials','email']) await assertFails(setDoc(doc(db('alice'),'families/alice'),{...family,[extra]:true}));
  await assertFails(setDoc(doc(db('alice'),'families/alice'),{locale:'tr'}));
  const profile={nickname:'Deniz',avatarId:'cat',ageRange:'4-6',survey:{},settings:{},createdAt:stamp(),updatedAt:stamp()};
  await assertSucceeds(setDoc(doc(db('alice'),'families/alice/profiles/profile-1'),profile));
  await assertFails(setDoc(doc(db('bob'),'families/alice/profiles/profile-1'),profile));
  await assertFails(setDoc(doc(db('alice'),'families/alice/profiles/profile-1'),{...profile,premium:true}));
  await assertFails(setDoc(doc(db('alice'),'families/alice/profiles/profile-1'),{...profile,nickname:'x'.repeat(25)}));
});
test('progress/item counters require bounded hints, counts, typed timestamps',async () => {
  const progress={themeId:'animals',modeId:'G01',difficulty:'easy',stages:5,independent:3,maxHint:4,updatedAt:stamp()};
  const ref=doc(db('alice'),'families/alice/profiles/profile-1/progress/animals-G01-easy');
  await assertSucceeds(setDoc(ref,progress));
  for(const change of [{maxHint:5},{stages:-1},{independent:6},{updatedAt:'date'},{trials:[]}]) await assertFails(setDoc(ref,{...progress,...change}));
  const item=doc(db('alice'),'families/alice/profiles/profile-1/itemStats/cat');
  const stats={correct:3,wrong:1,hintCounts:[0,1,2,0,0],updatedAt:stamp()};
  await assertSucceeds(setDoc(item,stats));
  for(const change of [{correct:-1},{wrong:true},{hintCounts:[0,-1,0,0,0]},{hintCounts:[0,0]},{hintCounts:{'0':3}}]) await assertFails(setDoc(item,{...stats,...change}));
});

test('announcements allow public exact reads, bounded admin text writes and no list',async () => {
  const payload={schemaVersion:1,title:{tr:'Yeni oyun',en:'New game'},body:{tr:'Birlikte keşfedin.',en:'Discover together.'}};
  await env.withSecurityRulesDisabled(async context => setDoc(doc(context.firestore(),'admins/admin'),{enabled:true}));
  const target='announcements/autumn-2026';
  await assertSucceeds(setDoc(doc(db('admin'),target),payload));
  for(const uid of [null,'alice','admin']) {
    await assertSucceeds(getDoc(doc(db(uid),target)));
    await assertFails(getDocs(collection(db(uid),'announcements')));
  }
  for(const uid of [null,'alice']) {
    await assertFails(setDoc(doc(db(uid),target),payload));
    await assertFails(deleteDoc(doc(db(uid),target)));
  }
  for(const change of [{schemaVersion:2},{schemaVersion:1.5},{url:'https://example.com'},{title:{}},{title:{fr:'Bonjour'}},{title:{en:'x'.repeat(121)},body:{en:'Body'}},{body:{tr:'x'.repeat(1201),en:'Body'}},{title:{tr:'Başlık'},body:{en:'Body'}}]) {
    await assertFails(setDoc(doc(db('admin'),target),{...payload,...change}));
  }
  await assertSucceeds(deleteDoc(doc(db('admin'),target)));
});

test('admin page: listed admin reads and deletes family data, others cannot',async () => {
  const profile={nickname:'Deniz',avatarId:'cat',ageRange:'4-6',survey:{},settings:{},createdAt:stamp(),updatedAt:stamp()};
  await assertSucceeds(setDoc(doc(db('alice'),'families/alice'),{createdAt:stamp(),updatedAt:stamp(),locale:'tr'}));
  await assertSucceeds(setDoc(doc(db('alice'),'families/alice/profiles/profile-1'),profile));
  await assertSucceeds(setDoc(doc(db('alice'),path),summary()));
  await assertSucceeds(setDoc(doc(db('alice'),'trials/alice'),{startedAt:serverTimestamp()}));
  await env.withSecurityRulesDisabled(async context => setDoc(doc(context.firestore(),'admins/admin'),{enabled:true}));
  // Only a pre-provisioned admin reads across families.
  for(const uid of ['bob','alice',null]) {
    await assertFails(getDocs(collection(db(uid),'trials')));
    await assertFails(getDocs(collectionGroup(db(uid),'sessions')));
    await assertFails(getDocs(collectionGroup(db(uid),'profiles')));
  }
  await assertFails(deleteDoc(doc(db('bob'),path)));
  const admin=db('admin');
  await assertSucceeds(getDocs(collection(admin,'trials')));
  await assertSucceeds(getDocs(collectionGroup(admin,'sessions')));
  await assertSucceeds(getDocs(collectionGroup(admin,'profiles')));
  await assertSucceeds(getDocs(collectionGroup(admin,'progress')));
  await assertSucceeds(getDocs(collectionGroup(admin,'itemStats')));
  await assertSucceeds(getDoc(doc(admin,'families/alice')));
  // Admin can delete data but never write it, and never touch trials/admins.
  await assertFails(setDoc(doc(admin,path),summary()));
  await assertFails(deleteDoc(doc(admin,'trials/alice')));
  await assertFails(setDoc(doc(admin,'admins/bob'),{enabled:true}));
  await assertSucceeds(deleteDoc(doc(admin,path)));
  await assertSucceeds(deleteDoc(doc(admin,'families/alice/profiles/profile-1')));
  await assertSucceeds(deleteDoc(doc(admin,'families/alice')));
});

test('family document may carry only the signed-in e-mail',async () => {
  const family={createdAt:stamp(),updatedAt:stamp(),locale:'tr'};
  const alice=env.authenticatedContext('alice',{email:'alice@example.com'}).firestore();
  await assertSucceeds(setDoc(doc(alice,'families/alice'),{...family,email:'alice@example.com'}));
  await assertFails(setDoc(doc(alice,'families/alice'),{...family,email:'bob@example.com'}));
});

test('grants: only admin writes a package or ends a trial; owner reads own',async () => {
  await env.withSecurityRulesDisabled(async context => setDoc(doc(context.firestore(),'admins/admin'),{enabled:true}));
  const grant={plan:'premium',until:null,endTrial:true,updatedAt:serverTimestamp()};
  await assertFails(setDoc(doc(db('alice'),'grants/alice'),grant));
  await assertSucceeds(setDoc(doc(db('admin'),'grants/alice'),grant));
  await assertSucceeds(setDoc(doc(db('admin'),'grants/alice'),{...grant,until:Timestamp.fromMillis(Date.now()+864e5)}));
  await assertFails(setDoc(doc(db('admin'),'grants/alice'),{...grant,plan:'gold'}));
  await assertFails(setDoc(doc(db('admin'),'grants/alice'),{...grant,extra:1}));
  await assertSucceeds(getDoc(doc(db('alice'),'grants/alice')));
  await assertFails(getDoc(doc(db('bob'),'grants/alice')));
  await assertFails(getDocs(collection(db('alice'),'grants')));
  await assertSucceeds(getDocs(collection(db('admin'),'grants')));
  await assertSucceeds(deleteDoc(doc(db('admin'),'grants/alice')));
});

test('family document accepts plan, lastSeenAt and appVersion',async () => {
  const family={createdAt:stamp(),updatedAt:stamp(),locale:'tr'};
  await assertSucceeds(setDoc(doc(db('alice'),'families/alice'),{...family,plan:'trial',lastSeenAt:stamp(),appVersion:'2.0.21+35'}));
  await assertFails(setDoc(doc(db('alice'),'families/alice'),{...family,plan:'gold'}));
  await assertFails(setDoc(doc(db('alice'),'families/alice'),{...family,lastSeenAt:'today'}));
});

test('funnel: anonymous install doc, each step stamped once, admin-only listing',async () => {
  await env.withSecurityRulesDisabled(async context => setDoc(doc(context.firestore(),'admins/admin'),{enabled:true}));
  const id='a1b2c3d4-e5f6-4711-8899-aabbccddeeff';
  const anon=db(null);
  await assertFails(setDoc(doc(anon,'funnel/short'),{installedAt:serverTimestamp(),platform:'android'}));
  await assertFails(setDoc(doc(anon,`funnel/${id}`),{installedAt:stamp(),platform:'android'}));
  await assertSucceeds(setDoc(doc(anon,`funnel/${id}`),{installedAt:serverTimestamp(),platform:'android',appVersion:'2.0.21',locale:'tr'}));
  await assertSucceeds(setDoc(doc(anon,`funnel/${id}`),{onboardingAt:serverTimestamp()},{merge:true}));
  await assertFails(setDoc(doc(anon,`funnel/${id}`),{onboardingAt:serverTimestamp()},{merge:true}));
  await assertSucceeds(setDoc(doc(anon,`funnel/${id}`),{obChildAt:serverTimestamp(),obFavoriteAt:serverTimestamp(),obKnownAt:serverTimestamp(),freeAt:serverTimestamp(),firstGameAt:serverTimestamp()},{merge:true}));
  await assertFails(setDoc(doc(anon,`funnel/${id}`),{firstGameAt:serverTimestamp()},{merge:true}));
  await assertFails(setDoc(doc(anon,`funnel/${id}`),{uid:'alice'},{merge:true}));
  await assertFails(getDoc(doc(anon,`funnel/${id}`)));
  await assertFails(getDocs(collection(db('alice'),'funnel')));
  await assertSucceeds(getDocs(collection(db('admin'),'funnel')));
});

test('admin page: per-family collection-group range finds only that family',async () => {
  await env.withSecurityRulesDisabled(async context => setDoc(doc(context.firestore(),'admins/admin'),{enabled:true}));
  await assertSucceeds(setDoc(doc(db('alice'),path),summary()));
  await assertSucceeds(setDoc(doc(db('bob'),path.replace('alice','bob')),summary()));
  const admin=db('admin');
  const range=uid=>query(collectionGroup(admin,'sessions'),orderBy(documentId()),startAt(`families/${uid}`),endAt(`families/${uid}//`));
  const snap=await assertSucceeds(getDocs(range('alice')));
  if(snap.docs.length!==1||!snap.docs[0].ref.path.startsWith('families/alice/')) throw new Error('range mismatch '+snap.docs.map(d=>d.ref.path));
});

test('feedback: app creates (signed in or not), only admin reads, marks and deletes',async () => {
  await env.withSecurityRulesDisabled(async context => setDoc(doc(context.firestore(),'admins/admin'),{enabled:true}));
  const base={message:'Çok güzel bir uygulama',createdAt:serverTimestamp(),uid:null,email:null,installId:'a1b2c3d4-e5f6-4711-8899-aabbccddeeff',appVersion:'2.0.22+36',locale:'tr',platform:'android'};
  await assertSucceeds(setDoc(doc(db(null),'feedback/f1'),base));
  const alice=env.authenticatedContext('alice',{email:'alice@example.com'}).firestore();
  await assertSucceeds(setDoc(doc(alice,'feedback/f2'),{...base,uid:'alice',email:'alice@example.com'}));
  await assertFails(setDoc(doc(alice,'feedback/f3'),{...base,uid:'bob'}));
  await assertFails(setDoc(doc(db(null),'feedback/f4'),{...base,email:'x@y.z'}));
  await assertFails(setDoc(doc(db(null),'feedback/f5'),{...base,message:''}));
  await assertFails(setDoc(doc(db(null),'feedback/f6'),{...base,message:'x'.repeat(2001)}));
  await assertFails(setDoc(doc(db(null),'feedback/f7'),{...base,createdAt:stamp()}));
  await assertFails(setDoc(doc(db(null),'feedback/f8'),{...base,extra:1}));
  await assertFails(getDoc(doc(alice,'feedback/f2')));
  await assertFails(getDocs(collection(alice,'feedback')));
  await assertFails(updateDoc(doc(alice,'feedback/f2'),{message:'changed'}));
  const admin=db('admin');
  await assertSucceeds(getDocs(collection(admin,'feedback')));
  await assertSucceeds(updateDoc(doc(admin,'feedback/f1'),{status:'read'}));
  await assertFails(updateDoc(doc(admin,'feedback/f1'),{status:'spam'}));
  await assertFails(updateDoc(doc(admin,'feedback/f1'),{message:'edited'}));
  await assertSucceeds(deleteDoc(doc(admin,'feedback/f1')));
});

test('feedback survey: ticked choice IDs with optional message',async () => {
  const base={message:'',createdAt:serverTimestamp(),uid:null,email:null,installId:'a1b2c3d4-e5f6-4711-8899-aabbccddeeff',appVersion:'2.0.22+36',locale:'tr',platform:'android'};
  const anon=db(null);
  await assertSucceeds(setDoc(doc(anon,'feedback/s1'),{...base,kind:'survey',choices:['more_games','price']}));
  await assertSucceeds(setDoc(doc(anon,'feedback/s2'),{...base,kind:'survey',choices:[],message:'Sadece yorum'}));
  await assertFails(setDoc(doc(anon,'feedback/s3'),{...base,kind:'survey',choices:[]}));
  await assertFails(setDoc(doc(anon,'feedback/s4'),{...base,kind:'survey',choices:['Bad Id!']}));
  await assertFails(setDoc(doc(anon,'feedback/s5'),{...base,kind:'survey',choices:['a','b','c','d','e','f','g','h','i']}));
  await assertFails(setDoc(doc(anon,'feedback/s6'),{...base,kind:'poll',choices:['a']}));
  await assertFails(setDoc(doc(anon,'feedback/s7'),{...base,message:''}));
  await assertFails(setDoc(doc(anon,'feedback/s8'),{...base,message:'x',choices:['a']}));
  await assertSucceeds(setDoc(doc(anon,'feedback/s9'),{...base,kind:'feedback',message:'Merhaba'}));
});

test('children: owner writes child profiles, admin reads and deletes, others cannot',async () => {
  await env.withSecurityRulesDisabled(async context => setDoc(doc(context.firestore(),'admins/admin'),{enabled:true}));
  const child={name:'Deniz',age:5,avatarId:'cat',settings:{sound:true},createdAt:stamp(),updatedAt:stamp()};
  const ref=uid=>doc(db(uid),'families/alice/children/child-1');
  await assertSucceeds(setDoc(ref('alice'),child));
  await assertSucceeds(setDoc(ref('alice'),{name:'Ela',ageBand:'4-6',createdAt:stamp(),updatedAt:stamp()}));
  await assertFails(setDoc(ref('alice'),{...child,name:''}));
  await assertFails(setDoc(ref('alice'),{...child,name:'x'.repeat(41)}));
  await assertFails(setDoc(ref('alice'),{...child,age:30}));
  await assertFails(setDoc(ref('alice'),{...child,photo:'x'}));
  await assertFails(setDoc(ref('bob'),child));
  await assertFails(getDoc(ref('bob')));
  await assertFails(setDoc(ref('admin'),child));
  await assertSucceeds(getDoc(ref('alice')));
  await assertSucceeds(getDocs(collectionGroup(db('admin'),'children')));
  await assertFails(getDocs(collectionGroup(db('bob'),'children')));
  await assertSucceeds(deleteDoc(ref('admin')));
});
