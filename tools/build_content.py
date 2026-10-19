"""Reproducible catalog -> CSV -> JSON and read-only Unity migration."""
import csv
import json
import re
import shutil
from install_selected_voice_samples import load_selected_audio
import hashlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
UNITY = Path('D:/GameDesktop/UnityProjects/SpecialEducationGames/Assets')
THEMES = [
 ('animals','Hayvanlar','Animals','FFFEFC','10B7B0','087B80','cat'),
 ('produce','Meyve ve Sebzeler','Fruit and Vegetables','FFFEFC','FF8A32','BA4C08','apple'),
 ('food','Yiyecek ve İçecekler','Food and Drinks','FFF3E0','E8A24D','C88333','bread'),
 ('vehicles','Taşıtlar','Vehicles','FFFEFC','1687D9','0868AF','car'),
 ('clothes','Kıyafet ve Aksesuarlar','Clothes','FBEFF3','D07A98','B25C7B','shirt'),
 ('home','Evimiz','Our Home','F4EFE8','A9805B','8B6441','bed'),
 ('school','Okul ve Oyuncaklar','School and Toys','EAF6F6','46A3A3','2F8585','ball'),
 ('jobs','Meslekler','Jobs','EEF0F8','6A78C2','4F5DA6','doctor'),
 ('nature','Doğa ve Mevsimler','Nature and Seasons','EDF6F0','5FA27A','45845F','sun'),
 ('music','Müzik Aletleri','Musical Instruments','F6EDF6','B572B0','965593','guitar'),
 ('body','Vücudumuz','Our Body','FDF1EA','DB8D6A','BC6F4D','hand'),
 ('colors','Renkler','Colors','FFFEFC','1687D9','0868AF','red'),
 ('shapes','Şekiller','Shapes','EAF1FA','5B8FD1','4071B3','circle'),
 ('numbers','Sayılar','Numbers','FFFEFC','FFB92E','AC6B00','3'),
 ('emotions','Duygular','Feelings','FFF6E0','E3B23C','C29322','happy'),
 ('letters','Harfler','Letters','F1F4F8','5F7896','465E7A','a'),
]
ALIASES = {'rooster':'cock','zucchini':'courgette','ladybug':'ladybird','rhinoceros':'rhino','grape':'grapes'}
normalize = lambda s: re.sub('[^a-z0-9]', '', s.lower())

def write_json(path, value):
 path.parent.mkdir(parents=True, exist_ok=True)
 path.write_text(json.dumps(value, ensure_ascii=False, indent=2), encoding='utf-8')

def load_real_photos(root=ROOT):
 """Only explicitly verified local adaptations may supersede legacy images."""
 manifest=root/'assets/content/real_photo_manifest.json'
 if not manifest.exists(): return {}
 result={}
 for photo in json.loads(manifest.read_text(encoding='utf-8'))['assets']:
  identifier=photo['id']
  if identifier in result: raise ValueError(f'Duplicate real photo: {identifier}')
  if photo.get('licenseVerified') is not True: raise ValueError(f'Unverified photo: {identifier}')
  variants=[photo]
  additional=photo.get('additionalVariants', [])
  if not isinstance(additional, list):
   raise ValueError(f'Invalid additionalVariants: {identifier}')
  variants.extend(additional)
  seen_paths=set()
  seen_hashes=set()
  for variant in variants:
   for field in ('author','source','license','licenseUrl','changes','sha256'):
    if not variant.get(field): raise ValueError(f'Missing {field}: {identifier}')
   if variant.get('licenseVerified') is not True:
    raise ValueError(f'Unverified photo variant: {identifier}')
   relative=Path(variant['path'])
   path=(root/relative).resolve()
   if relative.is_absolute() or not path.is_relative_to((root/'assets/images').resolve()):
    raise ValueError(f'Invalid real photo path: {identifier}')
   if path.suffix.lower()!='.png' or not path.is_file(): raise ValueError(f'Missing PNG: {identifier}')
   digest=hashlib.sha256(path.read_bytes()).hexdigest()
   if digest!=variant['sha256']:
    raise ValueError(f'Real photo hash mismatch: {identifier}')
   if relative.as_posix() in seen_paths or digest in seen_hashes:
    raise ValueError(f'Duplicate real photo variant: {identifier}')
   seen_paths.add(relative.as_posix())
   seen_hashes.add(digest)
  result[identifier]=photo
 return result

def catalog_image_fields(photo):
 variants=[photo, *photo.get('additionalVariants', [])]
 return ([variant['path'] for variant in variants],
         {variant['path']:variant for variant in variants})

def main():
 real_photos=load_real_photos()
 vehicle_manifest=ROOT/'assets/images/vehicles/generation_manifest.json'
 local_vehicles={x['slug']:x['path'] for x in json.loads(vehicle_manifest.read_text(encoding='utf-8'))} if vehicle_manifest.exists() else {}
 text = (ROOT/'icerik-katalogu.md').read_text(encoding='utf-8-sig')
 rows = []
 for number, body in re.findall(r'^## (\d+)\. (.*?)(?=^## |\Z)', text, re.M|re.S):
  index = int(number)-1
  if index >= len(THEMES): continue
  theme = THEMES[index][0]
  for tier_tr, tier in [('Kolay','easy'),('Orta','medium'),('Zor','hard')]:
   match = re.search(r'\*\*'+tier_tr+r'[^\n]*\*\*([^\n]*\n?.*?)(?=\n\*\*|\n---|\Z)', body, re.S)
   if not match: continue
   source = match[1]
   for name, slug, meta in re.findall(r'([^·\n:*]+?)\s*\(([a-z][a-z0-9_]*)\)([^·\n]*)', source):
    rows.append(dict(theme=theme,tier=tier,slug=slug,name_tr=name.strip(' –—'),name_en=slug.replace('_',' ').capitalize(),tags=','.join(re.findall(r'\[([^]]+)\]',meta)),needs_sfx='🔊' in meta,image_status='missing',audio_status='missing'))
 # Numeric content has a different catalog format.
 words_tr = ['Sıfır','Bir','İki','Üç','Dört','Beş','Altı','Yedi','Sekiz','Dokuz','On','On bir','On iki','On üç','On dört','On beş','On altı','On yedi','On sekiz','On dokuz','Yirmi']
 words_en = ['Zero','One','Two','Three','Four','Five','Six','Seven','Eight','Nine','Ten','Eleven','Twelve','Thirteen','Fourteen','Fifteen','Sixteen','Seventeen','Eighteen','Nineteen','Twenty']
 for n in range(21):
  rows.append(dict(theme='numbers',tier='easy' if 1<=n<=5 else 'medium' if 6<=n<=10 else 'hard',slug=str(n),name_tr=words_tr[n],name_en=words_en[n],tags='',needs_sfx=False,image_status='native',audio_status='missing'))
 selected_audio = load_selected_audio(ROOT, items={
  row['theme']+'.'+row['slug']: {'name': {'tr':row['name_tr'], 'en':row['name_en']}}
  for row in rows
 })
 assets = list(UNITY.rglob('*'))
 guids = {}
 for p in assets:
  if p.suffix=='.meta':
   m = re.search(r'^guid: (\w+)',p.read_text(errors='ignore'),re.M)
   if m: guids[m[1]] = Path(str(p)[:-5])
 images = {}
 for p in assets:
  if p.suffix.lower() in ('.png','.webp') and '_Project/UI' in p.as_posix():
   images.setdefault(normalize(p.stem),p)
 tables = {}
 shared=(UNITY/'Localization/Tables/AudioTable/AudioTable Shared Data.asset').read_text()
 key_ids={key:identifier for identifier,key in re.findall(r'm_Id: (\d+)\s+m_Key: ([^\n]+)',shared)}
 for lang in ('tr','en'):
  path=UNITY/f'Localization/Tables/AudioTable/AudioTable_{lang}.asset'
  tables[lang]=dict(re.findall(r'm_Id: (\d+)\s+m_Localized: (\w+)',path.read_text()))
 sound_defs={normalize(p.stem.replace('_SoundData','')):p for p in assets if p.name.endswith('_SoundData.asset')}
 migrated=[]
 def copy(src, relative):
  dest=ROOT/'assets'/relative; dest.parent.mkdir(parents=True,exist_ok=True)
  shutil.copy2(src,dest); migrated.append((relative,src.relative_to(UNITY).as_posix()))
  return 'assets/'+relative
 items=[]
 prompts={'next_number':'WhichOneIsTheNextNumber','compare':'CompareNumbers','retry':'TryOneMore','praise':'Success_01'}
 for prompt,key_name in prompts.items():
  for lang in ('tr','en'):
   src=guids.get(tables[lang].get(key_ids.get(key_name,''),''))
   if src and src.exists():copy(src,f'audio/{lang}/prompts/{prompt}{src.suffix}')
 seen=set()
 for row in rows:
  key=row['theme']+'.'+row['slug']
  if key in seen: continue
  seen.add(key)
  slug=row['slug']; norm=normalize(slug)
  candidates=[norm,normalize(ALIASES.get(slug,slug))]
  image=next((images[c] for c in candidates if c in images),None)
  image_paths=[]
  real_photo=real_photos.get(key)
  if real_photo:
   image_paths,_=catalog_image_fields(real_photo); row['image_status']='verified_real_photo'
  elif image and row['theme'] not in ('colors','numbers'):
   image_paths=[copy(image,f"images/{row['theme']}/{slug}_1{image.suffix}")]; row['image_status']='migrated'
  elif row['theme'] not in ('colors','numbers'):
   local_image=ROOT/f'assets/images/{row["theme"]}/{slug}_1.png'
   if row['theme']=='vehicles' and slug in local_vehicles:
    local_image=ROOT/local_vehicles[slug]
   if local_image.exists():
    image_paths=[local_image.relative_to(ROOT).as_posix()]; row['image_status']='local'
  audio={lang:selected_audio[(key,lang)]['path'] for lang in ('tr','en') if (key,lang) in selected_audio}
  if row['theme']=='numbers': candidates=[normalize(row['name_en'])]
  sound=next((sound_defs[c] for c in candidates if c in sound_defs),None)
  if sound:
   sound_text=sound.read_text()
   m=re.search(r'm_KeyId: (\d+)',sound_text)
   if m:
    identifier=m[1]
    if identifier=='0':
     named=re.search(r'\bm_Key: ([^\n]+)',sound_text)
     if named: identifier=key_ids.get(named[1].strip(),'0')
    for lang in ('tr','en'):
     if lang in audio: continue
     src=guids.get(tables[lang].get(identifier,''))
     if src and src.exists(): audio[lang]=copy(src,f'audio/{lang}/{row["theme"]}/{slug}{src.suffix}')
  if audio: row['audio_status']='selected' if any((key,lang) in selected_audio for lang in audio) else 'migrated'
  tier=row['tier']; rank={'easy':0,'medium':1,'hard':2}[tier]
  index=sum(1 for x in items if x['theme']==row['theme'] and x['tier']==tier)
  sfx_path=f'assets/sfx/{row["theme"]}/{slug}.mp3'
  items.append(dict(id=key,theme=row['theme'],tier=tier,chapter=rank*2+1+min(1,index//8),tags=row['tags'].split(',') if row['tags'] else [],name={'tr':row['name_tr'],'en':row['name_en']},images=image_paths,audio=audio,sfx=sfx_path if (ROOT/sfx_path).exists() else None))
  if real_photo:
   _,items[-1]['imageProvenance']=catalog_image_fields(real_photo)
  audio_provenance={lang:selected_audio[(key,lang)] for lang in audio if (key,lang) in selected_audio}
  if audio_provenance: items[-1]['audioProvenance']=audio_provenance
 unknown=set(real_photos)-seen
 if unknown: raise ValueError(f'Unknown real photo IDs: {sorted(unknown)}')
 with (ROOT/'content_source.csv').open('w',encoding='utf-8-sig',newline='') as f:
  writer=csv.DictWriter(f,fieldnames=rows[0].keys()); writer.writeheader(); writer.writerows(rows)
 for t in THEMES:
  write_json(ROOT/f'assets/content/items/{t[0]}.json',[x for x in items if x['theme']==t[0]])
 active=['animals','produce','colors','numbers','vehicles']
 theme_games={
 'animals':['G01','G10','G02','G14','G04','G33','G36','G55','G15','G17','G23'],
 'produce':['G01','G02','G14','G04','G33','G36','G55','G15','G17','G23','G38'],
 'colors':['G01','G02','G14','G55'],
 'numbers':['G35','G02','G10','G14','G33','G34','G36','G55','G37','G38'],
 'vehicles':['G02','G01','G10','G14','G04','G33','G36','G55','G15','G17','G23'],
 }
 write_json(ROOT/'assets/content/themes.json',[dict(id=t[0],name={'tr':t[1],'en':t[2]},palette=dict(zip(['bg','accent','deep'],['#'+x for x in t[3:6]])),hero=t[0]+'.'+t[6],active=t[0] in active,games=theme_games.get(t[0],[])) for t in THEMES])
 game_defs=[('G01','Bul','Find','identify'),('G02','Öğren','Learn','flashcards'),('G04','Hangi Grupta?','Which Group?','identify'),('G10','Sesini Bul','Find the Sound','audio_choice'),('G14','Aynısını Bul','Find the Match','identify'),('G33','Say ve Seç','Count and Choose','count'),('G34','Rakamı Bul','Find the Number','identify'),('G35','Sonraki Sayı','Next Number','sequence_missing'),('G36','Karşılaştır','Compare','compare'),('G55','Dokun-Keşfet','Touch and Explore','cause_effect'),('G15','Gölgesini Bul','Find the Shadow','drag_to_target'),('G17','Farklı Olanı Bul','Odd One Out','odd_one_out'),('G23','Sepete Koy','Into the Basket','sort'),('G37','Sayı ve Miktar','Number and Amount','match_pair'),('G38','Sepeti Doldur','Fill the Basket','fill_count')]
 phase_two={'G15','G17','G23','G37','G38'}
 write_json(ROOT/'assets/content/games.json',[dict(id=i,name={'tr':tr,'en':en},template=temp,phase=2 if i in phase_two else 1) for i,tr,en,temp in game_defs])
 write_json(ROOT/'assets/config_defaults.json',dict(freeGames=['animals_G01','produce_G01','colors_G01','animals_G10','numbers_G35','vehicles_G02'],disabledGames=[],hiddenThemes=[],difficultyDefaults={'fadeAfterErrors':2}))
 write_json(ROOT/'assets/content/migration_report.json',dict(items=len(items),images=sum(bool(x['images']) for x in items),verifiedRealPhotos=len(real_photos),selectedVoiceRecordings=len(selected_audio),audio=sum(bool(x['audio']) for x in items),missing=[x['id'] for x in items if not x['images'] and x['theme'] not in ('colors','numbers')]))
 photo_credits='\n\n## Verified real photo adaptations\n\nDetailed credits are bundled in `assets/content/real_photo_manifest.json` and `assets/content/REAL_PHOTOS.md`. Each adaptation retains its recorded source license. Legacy/generated files are preserved, and are not made verified by this override.\n\n'+ '\n'.join(f"- `{variant['path']}` — {variant['author']}; {variant['license']} ({variant['licenseUrl']}); source: {variant['source']}. Changes: {variant['changes']}" for photo in real_photos.values() for variant in [photo, *photo.get('additionalVariants', [])])
 (ROOT/'assets/LICENSES.md').write_text('# Asset provenance\n\nExisting assets copied from the owner’s Unity project. Original third-party licenses require owner verification before release. No license ownership is inferred.\n\n'+ '\n'.join(f'- `{a}` ← `{b}`' for a,b in migrated)+photo_credits,encoding='utf-8')
 print(f'{len(items)} items; {len(migrated)} migrated files. CSV + JSON generated.')

if __name__=='__main__': main()
