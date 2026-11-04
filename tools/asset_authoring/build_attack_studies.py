"""Render the fifteen review-only choreographies. Never changes runtime asset pins."""
from pathlib import Path
import argparse
from contextlib import nullcontext
import base64
import hashlib
import json
import subprocess
import threading
import time
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from concurrent.futures import ThreadPoolExecutor
from PIL import Image
from playwright.sync_api import sync_playwright

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'builds' / 'attack-studies-v2'
OUT.mkdir(parents=True, exist_ok=True)
ASSETS = ROOT / 'assets'


def encoded(path):
    return 'data:image/png;base64,' + base64.b64encode(path.read_bytes()).decode()


def build(revision=2, html_only=False):
    global OUT
    OUT = ROOT / 'builds' / f'attack-studies-v{revision}'
    OUT.mkdir(parents=True, exist_ok=True)
    data = {'images': {}, 'regions': {}}
    sources = []
    for atlas, module in [('creatures', 'battle-creatures'), ('evolved', 'battle-evolved')]:
        folder = ASSETS / 'characters' / module / 'versions/1.0.0'
        data['images'][atlas] = encoded(folder / 'texture.png')
        sources.append(folder / 'texture.png')
        atlas_data=json.loads((folder / 'atlas.json').read_text())
        for name, region in atlas_data['regions'].items():
            data['regions'][name] = {'atlas': atlas, 'rect': region, 'grounding':atlas_data.get('grounding',{}).get(name)}
    background = ASSETS / 'world/battle-clearing-depth/versions/1.0.0/background.png'
    data['images']['background'] = encoded(background)
    sources.append(background)
    if revision >= 4:
        vfx = ASSETS / 'attacks/woodland-elements/versions/1.0.0/source-atlas.png'
        data['images']['vfxAtlas'] = encoded(vfx)
        sources.append(vfx)
    if revision >= 5:
        from attack_study_audio import build_audio
        choreography = ROOT / 'tools/asset_authoring/attack_choreography.json'
        data['choreography'] = json.loads(choreography.read_text())
        build_audio(data['choreography'], OUT)
        data['audio'] = {str(i):'data:audio/wav;base64,'+base64.b64encode((OUT/'audio'/f'{i+1:02d}.wav').read_bytes()).decode() for i in range(15)}
        sources.append(choreography)
    template = Path(__file__).with_name('attack_studies.html')
    html = template.read_text().replace('__DATA__', json.dumps(data))
    base = subprocess.check_output(['git', 'rev-parse', '--short', 'HEAD'], cwd=ROOT, text=True).strip()
    html = html.replace('Main 44943dc', f'Main {base} · Revisão corporal 0{revision}')
    html = html.replace('O bosque ganha movimento.', 'Cada Umbral tem seu gesto.' if revision >= 3 else 'O golpe nasce no corpo.')
    html = html.replace('Compare a antecipação, a trajetória e o impacto com os sprites originais de Umbral.', 'Boca, cauda, patas, galhos, reservatório e antenas: cada saída tem preparação, disparo e recuperação próprios.')
    html = html.replace('Movimentos de corpo usam os sprites existentes: poses anatômicas quadro a quadro e integração no Godot são etapas posteriores.', 'Revisão 02: articulações deformam uma malha contínua do sprite original. Pontos de emissão acompanham a anatomia animada; ainda não há novas poses redesenhadas quadro a quadro ou integração Godot.')
    html = html.replace('max="2"', 'max="3.2"').replace('%2;', '%3.2;')
    names = ['attack_actor_rig.js', 'attack_studies_v2.js']
    if revision >= 3:
        names += ['umbral_anatomy.js', 'attack_studies_v3.js']
    if revision >= 4:
        names += ['attack_studies_v4.js']
    if revision >= 5:
        names += ['attack_personalities.js','attack_studies_v5.js','attack_study_sound.js']
    extra = '\n'.join(Path(__file__).with_name(name).read_text() for name in names)
    if revision >= 3:
        extra = extra.replace('rig.joint([.78,.10])', '(rig.secondary||rig.joint([.78,.10]))')
        html = html.replace('Revisão 02:', 'Revisão 03: pontos calibrados por forma e seis estados de personagem;')
        html = html.replace('Boca, cauda, patas, galhos, reservatório e antenas: cada saída tem preparação, disparo e recuperação próprios.', 'Oito formas com repouso, preparação, conjuração, dano, defesa e celebração. Quinze golpes com saídas calibradas por forma e impactos em camadas.')
    if revision >= 4:
        html = html.replace('Cada Umbral tem seu gesto.', 'Elementos vivos. Golpes com presença.')
        html = html.replace('Revisão 03:', 'Revisão 04: atlas ilustrado de efeitos;')
    if revision >= 5:
        html = html.replace('Estudos de coreografia e VFX, sem áudio.', 'Estudos de coreografia e VFX com sonoplastia original sincronizada.')
        html = html.replace('Nenhuma regra, versão de asset ou vínculo de produção foi alterado.', 'Prévia independente do Godot. Números e reações ilustram a apresentação; não alteram as regras.')
    html = html.replace('</script>', extra + '\n</script>')
    (OUT / 'galeria.html').write_text(html)
    if html_only:
        print(OUT / 'galeria.html')
        return
    errors = []
    class QuietHandler(SimpleHTTPRequestHandler):
        def log_message(self, *_args):
            pass
    server = ThreadingHTTPServer(('127.0.0.1', 0), partial(QuietHandler, directory=str(OUT)))
    threading.Thread(target=server.serve_forever, daemon=True).start()
    # Durable frame cache: a runtime restart must not discard a long render.
    inputs = {name:hashlib.sha256(Path(__file__).with_name(name).read_bytes()).hexdigest()
              for name in names+['attack_studies.html','build_attack_studies.py']}
    inputs.update({str(p.relative_to(ROOT)):hashlib.sha256(p.read_bytes()).hexdigest() for p in sources})
    cache = OUT/'frame-cache'
    if cache.exists() and (not (cache/'inputs.json').exists() or json.loads((cache/'inputs.json').read_text()) != inputs):
        cache.rename(OUT/f'frame-cache-previous-{time.time_ns()}')
    cache.mkdir(exist_ok=True)
    (cache/'inputs.json').write_text(json.dumps(inputs,indent=2))
    with nullcontext(cache) as tmp:
        frames = Path(tmp)
        for i in range(15):
            (frames / str(i)).mkdir(exist_ok=True)
        with sync_playwright() as p:
            browser = p.chromium.launch(executable_path='/usr/bin/chromium', headless=True, args=['--no-sandbox'])
            page = browser.new_page(viewport={'width': 1440, 'height': 1000}, device_scale_factor=1)
            page.on('pageerror', lambda error: errors.append(str(error)))
            page.goto(f'http://127.0.0.1:{server.server_port}/galeria.html')
            page.wait_for_function('window.loaded === true')
            print('Gallery loaded with original sprites and arena', flush=True)
            for frame in range(96):
                if all((frames/str(i)/f'{frame:03d}.png').exists() for i in range(15)):
                    continue
                images = page.evaluate('(t) => window.renderFrame(t)', frame / 30)
                for i, encoded_frame in enumerate(images):
                    (frames / str(i) / f'{frame:03d}.png').write_bytes(base64.b64decode(encoded_frame))
                if frame % 16 == 0:
                    print(f'Rendered {frame}/96 frames × 15 studies', flush=True)
            if revision >= 5:
                (OUT/'choreography.json').write_text(json.dumps(page.evaluate('window.choreographySpecs()'),indent=2,ensure_ascii=False))
                (OUT/'personalities.json').write_text(json.dumps(page.evaluate('window.personalityMetrics()'),indent=2,ensure_ascii=False))
                performances = page.evaluate('window.performanceMetrics()')
                for performance in performances:
                    for start, final in zip(performance['poses'][0]['forms'],performance['poses'][-1]['forms']):
                        assert start['x']==final['x'] and start['y']==final['y'], performance['index']
                    assert len({round(p['x'],3) for p in performance['reactions']}) >= 4
                (OUT/'performances.json').write_text(json.dumps(performances,indent=2,ensure_ascii=False))
            metrics = page.evaluate('window.rigMetrics()')
            assert len({entry['source'] for entry in metrics}) >= 12
            for entry in metrics:
                rest, windup, release, contact, final = entry['poses']
                assert any(abs(a-b) > .1 for a,b in zip(rest['angles'], release['angles'])), entry
                assert rest['root'] == final['root'] and rest['angles'] == final['angles'], entry
            (OUT / 'rig-motion.json').write_text(json.dumps(metrics, indent=2, ensure_ascii=False))
            if revision >= 3:
                anatomy = page.evaluate('window.personalityMetrics()' if revision>=5 else 'window.anatomyMetrics()')
                emissions = page.evaluate('window.emissionMetrics()')
                assert len(anatomy) == 8 and all(len(f['states']) == 6 for f in anatomy)
                for form in anatomy:
                    signatures={json.dumps([{k:p[k] for k in ['x','y','head','fore','hind','tail','crest','bob']} for p in state['poses']],sort_keys=True) for state in form['states']}
                    assert len(signatures)==6, form['id']
                for entry in emissions:
                    for form in entry['forms']:
                        assert all(abs(a-b)<.0001 for a,b in zip(form['release'], form['drawSocket'])), form
                        assert all(0<=u<=1 for u in form['uv'])
                assert any(e['forms'][0]['uv'] != e['forms'][1]['uv'] for e in emissions)
                (OUT/'anatomy.json').write_text(json.dumps(anatomy,indent=2,ensure_ascii=False))
                (OUT/'emission-points.json').write_text(json.dumps(emissions,indent=2,ensure_ascii=False))
                # Eight forms × six states, a full 3.2-second cycle at 30 FPS.
                library_dir = frames/'life'
                library_dir.mkdir(exist_ok=True)
                for state in range(6):
                    for frame in range(96):
                        if (library_dir/f'{state*96+frame:03d}.png').exists():
                            continue
                        images = page.evaluate('([t,s]) => window.renderLifeFrame(t,s)',[frame/30,state])
                        sheet = Image.new('RGB',(1280,480),'#0b171c')
                        from io import BytesIO
                        for i,encoded_frame in enumerate(images):
                            im = Image.open(BytesIO(base64.b64decode(encoded_frame))).convert('RGB')
                            sheet.paste(im,((i%4)*320,(i//4)*240))
                        sheet.save(library_dir/f'{state*96+frame:03d}.png')
                    print(f'Rendered creature state {state+1}/6 × 8 forms',flush=True)
                page.locator('#life-state').select_option('2')
                page.evaluate('window.renderLifeFrame(1.2,2)')
                page.locator('#actor-library').screenshot(path=str(OUT/'vida-umbrals.png'))
            page.evaluate('window.renderFrame(1.12)')
            page.screenshot(path=str(OUT / 'galeria-desktop.png'), full_page=True)
            # Exercise real gallery controls, including per-clip seeking and enlarged view.
            page.evaluate('window.exportMode = false')
            page.locator('#play').click()
            page.locator('#speed').select_option('.25')
            page.locator('[data-pause="0"]').click()
            page.locator('article input').first.fill('0.7')
            assert page.evaluate('states[0].paused && states[0].time === .7')
            page.locator('[data-expand="0"]').click()
            assert page.locator('dialog').evaluate('(d) => d.open')
            page.keyboard.press('Escape')
            if revision >= 5:
                page.locator('#sound-clip').select_option('13')
                page.locator('#listen').click()
                page.wait_for_function('soundPreview.active && states[13].time > .05')
                page.keyboard.press('Escape')
                assert page.evaluate('!soundPreview.active')
                page.locator('#victim').select_option('verdalio')
                page.evaluate('window.renderFrame(1.4)')
                page.locator('#victim').select_option('auto')
            page.locator('#joints').check()
            page.evaluate('window.renderFrame(.88)')
            page.screenshot(path=str(OUT / 'articulacoes.png'), full_page=True)
            page.locator('#joints').uncheck()
            page.locator('#reduced').check()
            page.locator('#evolved').uncheck()
            page.evaluate('window.renderFrame(.65)')
            page.screenshot(path=str(OUT / 'movimento-reduzido.png'), full_page=True)
            page.set_viewport_size({'width': 390, 'height': 844})
            page.screenshot(path=str(OUT / 'galeria-mobile.png'), full_page=True)
            assert page.evaluate('document.documentElement.scrollWidth <= innerWidth')
            assert not errors, errors
            browser.close()
        overview_frames = frames / 'overview'
        overview_frames.mkdir(exist_ok=True)
        for f in range(96):
            sheet = Image.new('RGB', (960, 900), '#0b171c')
            for i in range(15):
                im = Image.open(frames / str(i) / f'{f:03d}.png').convert('RGB')
                sheet.paste(im.resize((320, 180), Image.Resampling.LANCZOS), ((i % 3) * 320, (i // 3) * 180))
            sheet.save(overview_frames / f'{f:03d}.png')
        Image.open(overview_frames / '032.png').save(OUT / 'comparativo.png')
        # Pose strips allow visual review of local motion rather than a single hit frame.
        for i in range(15):
            sheet = Image.new('RGB', (1920, 360), '#0b171c')
            duration = [1.45,1.75,1.65,1.70,1.90,1.80,1.40,1.85,1.80,1.30,1.65,1.70,1.85,2.10,2][i]
            for j,q in enumerate([.05,.24,.42,.66,.82,1.02]):
                times = ([.25, data['choreography'][i]['release']-.05, data['choreography'][i]['release']+.08, data['choreography'][i]['contact'], data['choreography'][i]['contact']+.28, 2.7] if revision>=5 else [.32+x*duration for x in [.05,.24,.42,.66,.82,1.02]])
                f = min(95, round(times[j]*30))
                im = Image.open(frames / str(i) / f'{f:03d}.png').convert('RGB')
                sheet.paste(im.resize((320,180)), (j*320,0))
            sheet.crop((0,0,1920,180)).save(OUT / f'{i+1:02d}-poses.png')

        def video(i):
            src = frames / str(i)
            filename = f'{i+1:02d}' if isinstance(i, int) else 'comparativo'
            subprocess.run(['ffmpeg', '-v', 'error', '-y', '-framerate', '30', '-i', str(src / '%03d.png'), '-c:v', 'libx264', '-crf', '18', '-pix_fmt', 'yuv420p', '-movflags', '+faststart', str(OUT / f'{filename}.mp4')], check=True)
            if revision >= 5 and isinstance(i, int):
                silent = OUT/f'{filename}-silent.mp4'
                (OUT/f'{filename}.mp4').replace(silent)
                subprocess.run(['ffmpeg','-v','error','-y','-i',str(silent),'-i',str(OUT/'audio'/f'{filename}.wav'),'-c:v','copy','-c:a','aac','-b:a','160k','-shortest','-movflags','+faststart',str(OUT/f'{filename}.mp4')],check=True)
                silent.unlink()
            subprocess.run(['ffmpeg', '-v', 'error', '-y', '-i', str(OUT / f'{filename}.mp4'), '-filter_complex', '[0:v]fps=20,scale=480:-1:flags=lanczos,split[a][b];[a]palettegen=stats_mode=diff[p];[b][p]paletteuse=dither=bayer:bayer_scale=3', '-loop', '0', str(OUT / f'{filename}.gif')], check=True)
            return filename

        with ThreadPoolExecutor(max_workers=3) as pool:
            for name in pool.map(video, list(range(15)) + ['overview']):
                print('Encoded', name, flush=True)
        if revision >= 3:
            subprocess.run(['ffmpeg','-v','error','-y','-framerate','30','-i',str(library_dir/'%03d.png'),'-c:v','libx264','-crf','18','-pix_fmt','yuv420p','-movflags','+faststart',str(OUT/'vida-umbrals.mp4')],check=True)
        concat = frames / 'clips.txt'
        concat.write_text('\n'.join(f"file '{OUT / f'{i+1:02d}.mp4'}'" for i in range(15)))
        subprocess.run(['ffmpeg', '-v', 'error', '-y', '-f', 'concat', '-safe', '0', '-i', str(concat), '-c', 'copy', '-movflags', '+faststart', str(OUT / '15-animacoes.mp4')], check=True)
    metadata = {'revision': revision, 'base': subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip(), 'studies': 15, 'fps': 30, 'frames_per_study': 96, 'runtime_integration': False, 'audio': revision>=5, 'browser_errors': errors, 'checks': ['15 skinned performances', 'at least 12 named emission sockets', 'independent joint motion in every performance', 'restored roots and bone angles', 'pause', 'seek', 'speed control', 'enlarge and Escape', 'joint overlay', 'reduced motion', 'base and evolved forms', '390px without horizontal overflow'], 'provenance': [{'path': str(p.relative_to(ROOT)), 'sha256': hashlib.sha256(p.read_bytes()).hexdigest()} for p in sources], 'limits': ['Continuous mesh skinning of original sprites; not redrawn frame-by-frame animation.', 'Canvas choreography studies, not integrated Godot effects.', 'No hardware performance or subjective playtest claim.']}
    if revision >= 3:
        metadata.update({'creature_forms':8,'creature_states':6,'creature_performances':48,'calibrated_emission_performances':30,'checks':metadata['checks']+['8 forms × 6 states','30 posed emission points agree with the rendered actor','form-specific source positions','optional impact light defaults off']})
    if revision >= 5:
        metadata['checks'] += ['15 event clocks shared by sound and motion','species-specific target selection and reactions','3 distinct response beats for thorn volley']
        metadata['limits'].append('Original synthesized audio; physical listening test not performed.')
    (OUT / 'review.json').write_text(json.dumps(metadata, indent=2, ensure_ascii=False))
    (OUT / 'LEIA-ME.txt').write_text(f'UMBRAL — revisão corporal 0{revision}, quinze animações\n\nAbra galeria.html em qualquer navegador; funciona offline.\nControles: pausa global/individual, tempo, câmera lenta, ampliar, formas iniciais/evoluídas, articulações/saídas e movimento reduzido.\n15-animacoes.mp4 contém todos em sequência (48s).\n01–03 Bola de fogo; 04–06 Chicote de espinhos; 07–09 Jato de orvalho; 10–12 Arco elétrico; 13–15 Mergulho trovão.\nEm cada grupo: A, B, C.\nComparativo mostra os 15 ao mesmo tempo.\nCada saída segue a mesma transformação de pele/articulações da anatomia, com reação e recuperação próprias.\nEstudos visuais sem áudio e sem integração no runtime. Malha contínua sobre os sprites originais; não são poses redesenhadas quadro a quadro.\n'+('vida-umbrals.mp4: seis estados em oito formas (19,2s).\n' if revision>=3 else ''))
    if revision >= 5:
        readme=OUT/'LEIA-ME.txt'
        readme.write_text(readme.read_text().replace('sem áudio e sem integração','com sonoplastia original sintetizada, sem integração')+'\nUse Assistir com som para uma cena por vez. Alterne Quem recebe para comparar reações. Impacto de câmera pode ser desligado; movimento reduzido elimina deslocamentos e partículas.\n')
    print('Done:', OUT, flush=True)
    server.shutdown()


if __name__ == '__main__':
    parser=argparse.ArgumentParser()
    parser.add_argument('--revision',type=int,choices=[2,3,4,5],default=2)
    parser.add_argument('--html-only',action='store_true')
    args=parser.parse_args()
    build(args.revision,args.html_only)
