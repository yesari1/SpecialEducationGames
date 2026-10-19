"""Small four-sound prototype set for the free audio-choice game."""
import json,subprocess
from pathlib import Path
from voice_samples import api
root=Path(__file__).resolve().parents[1]
sounds={'cat':'A single domestic cat meowing gently, recognizable natural meow, close isolated recording, no music, no speech, no background noise.','dog':'A small friendly dog giving two soft short barks, recognizable natural woof, no growling, no music, no speech, no background noise.','cow':'One calm cow mooing softly, recognizable natural moo, isolated recording, no music, no speech, no background noise.','horse':'One horse neighing softly, recognizable natural neigh, isolated recording, no hoof sounds, no music, no speech, no background noise.'}
manifest=[]
for slug,prompt in sounds.items():
    path=root/f'assets/sfx/animals/{slug}.mp3';path.parent.mkdir(parents=True,exist_ok=True)
    raw=root/f'voice_samples/sfx_{slug}_raw.mp3'
    if not raw.exists():raw.write_bytes(api('sound-generation',{'text':prompt,'duration_seconds':2.0,'prompt_influence':0.5,'model_id':'eleven_text_to_sound_v2'}))
    subprocess.run(['ffmpeg','-y','-hide_banner','-loglevel','error','-i',str(raw),'-af','loudnorm=I=-24:TP=-6:LRA=7','-ar','44100',str(path)],check=True)
    manifest.append({'slug':slug,'prompt':prompt,'model':'eleven_text_to_sound_v2','file':path.relative_to(root).as_posix(),'review':'Prototype; adult review required before release'})
    print(slug)
(root/'assets/sfx/manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf-8')
items_path=root/'assets/content/items/animals.json';items=json.loads(items_path.read_text(encoding='utf-8'))
for item in items:
    if item['id'].split('.')[-1] in sounds:item['sfx']='assets/sfx/animals/'+item['id'].split('.')[-1]+'.mp3'
items_path.write_text(json.dumps(items,ensure_ascii=False,indent=2),encoding='utf-8')
