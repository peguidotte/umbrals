"""Record a real committed reserve entry, KO and revival through browser controls."""
import argparse
import base64
import json
import subprocess
import sys
from pathlib import Path
from types import SimpleNamespace

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from browser.session import Session
from capture_battle_performances import AUDIO_CAPTURE


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--build-dir", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)
    (args.output / ".gdignore").touch()
    session = Session(SimpleNamespace(output=args.output, build_dir=args.build_dir,
        viewport="1600x900", video=False, large_text=False, fixture=None,
        scenario="combat", capture_audio=True))
    session.context.add_init_script(AUDIO_CAPTURE)
    evidence = []

    def shot(name):
        state = session.state()
        session.page.screenshot(path=str(args.output / (name + ".png")))
        (args.output / (name + ".state.json")).write_text(json.dumps(state, ensure_ascii=False, indent=2))
        evidence.append({"name": name, "screen": state["screen"], "actions": state["actions"]})

    try:
        session.fixture("brasa_lifecycle")
        shot("01-before-entry")
        session.page.evaluate("""() => {
            const stream=document.querySelector('canvas').captureStream(30);
            const audio=window.__gameAudio;
            if(!audio) throw new Error('Actual game audio output was not observed');
            audio.__recordOutput.stream.getAudioTracks().forEach(t=>stream.addTrack(t));
            const recorder=new MediaRecorder(stream,{mimeType:'video/webm;codecs=vp8,opus',videoBitsPerSecond:5000000});
            const chunks=[];recorder.ondataavailable=e=>{if(e.data.size)chunks.push(e.data)};
            window.__lifecycleRecording={recorder,chunks,started:performance.now()};recorder.start(100);
        }""")
        session.click("reserve.0")
        session.click("swap.slot.1")
        session.check(next(u for u in session.state()["party"] if u["uid"] == 1)["slot"] == -1,
                      "Planning keeps Brasa in reserve")
        session.page.keyboard.press("Space")
        session.wait("window.umbralState.busy")
        # Reading pixels here stalls the compositor and distorts visible cadence.
        # Extract the entry still from the completed video instead.
        entry_time = session.page.evaluate("() => (performance.now()-window.__lifecycleRecording.started)/1000 + 0.14")
        session.settled()
        session.page.wait_for_timeout(700)
        state = session.state()
        session.check(next(u for u in state["party"] if u["uid"] == 1)["hp"] == 0,
                      "Committed enemy action actually incapacitated Brasa")
        if state["screen"] == "ko_replacement": session.click("ko.finish")
        session.page.wait_for_timeout(150)
        shot("03-knockout-held")
        session.click("hud.backpack")
        session.click("pouch.revive.0")
        session.page.keyboard.press("Space")
        session.wait("window.umbralState.busy")
        session.settled()
        session.page.wait_for_timeout(1000)
        session.check(next(u for u in session.state()["party"] if u["uid"] == 1)["hp"] > 0,
                      "Owned item actually revives the same Brasa")
        shot("04-revived")
        encoded = session.page.evaluate("""async () => {
            const {recorder,chunks}=window.__lifecycleRecording;
            await new Promise(r=>{recorder.onstop=r;recorder.stop()});
            return await new Promise(r=>{const reader=new FileReader();reader.onload=()=>r(reader.result.slice(reader.result.indexOf('base64,')+7));reader.readAsDataURL(new Blob(chunks,{type:recorder.mimeType}))});
        }""")
        raw = args.output / "brasa-lifecycle.webm"
        raw.write_bytes(base64.b64decode(encoded))
        subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", str(raw), "-c:v", "libx264",
                        "-crf", "19", "-pix_fmt", "yuv420p", "-c:a", "aac", "-movflags", "+faststart",
                        str(args.output / "brasa-lifecycle.mp4")], check=True)
        subprocess.run(["ffmpeg", "-v", "error", "-y", "-ss", str(entry_time), "-i",
                        str(args.output / "brasa-lifecycle.mp4"), "-frames:v", "1",
                        str(args.output / "02-entry-from-video.png")], check=True)
        session.check(not session.errors, "No browser script errors during real lifecycle input")
        (args.output / "capture-report.json").write_text(json.dumps({"checks": session.checks,
            "captures": evidence, "errors": session.errors, "audio_source": "Actual game WebAudio output",
            "entry_still": {"file": "02-entry-from-video.png", "video_seconds": entry_time,
                            "method": "Extracted after recording; no screenshot during entry"}}, ensure_ascii=False, indent=2))
        print(json.dumps({"video": str(args.output / "brasa-lifecycle.mp4"), "captures": evidence}))
    finally:
        session.browser.close()
        session.playwright.stop()
        session.server.shutdown()


if __name__ == "__main__":
    main()
