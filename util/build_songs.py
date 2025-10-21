import os
import zipfile
import re
import json
import sys
from urllib.request import urlretrieve
from string import Template
from pathlib import Path

CWD = Path.cwd()
ARCHIVE_PATH = Path(".").joinpath("sangbog-main.zip")
JSON_PATH = CWD.joinpath("songs.json")

### EXTRACTING PART ###
def get_songbook(file_path):
    url = 'https://github.com/f-klubben/sangbog/archive/master.zip'
    urlretrieve(url, file_path)
    print("")
    return file_path

def get_file_contents(archive, path):
    contents = ""
    with archive.open(path, mode="r") as data:
        contents = data.read()
    return contents

def get_song_info(content):
    reg = re.compile(r"\\begin\{sang\}\{([^\}]*)\}\{([^\}]*)\}")
    match = reg.match(content)
    if match != None:
        return (
            match.group(1).capitalize(), 
            match.group(2).replace("\\ldots", "…").replace("Melodi - ", "").replace("Melodi:", "").lstrip().capitalize()
        )

def get_verses(content):
    matches = re.compile(r"(?s)\\begin\{vers\}\s?(.*?)\\end\{vers\}", re.MULTILINE|re.DOTALL)
    res = []
    for match in matches.finditer(content):
        start = content[0:match.start()].count("\n")
        res.append((start, "v",match.group(1)))
    return res

def get_choruses(content):
    matches = re.compile(r"\\begin\{omkvaed\}\[?\w?\]?\s*([^\\]*)", re.MULTILINE|re.DOTALL)
    res = []
    for match in matches.finditer(content):
        start = content[0:match.start()].count("\n")
        res.append((start,"c", match.group(1)))
    return res

def get_images(content):
    matches = re.compile(r"\\includegraphics\s*\[width=(\d*.\d)\\*\w*\]\{([^\}]*)\}", re.MULTILINE|re.DOTALL)
    res = []
    for match in matches.finditer(content):
        start = content[0:match.start()].count("\n")
        res.append((start, "i", match.group(1),match.group(2).replace(".eps", ".png")))
    return res

def get_song_order(content):
    matches = re.compile(r"\\input\{([^\}]*)\/([^.}]*)(.tex|\})", re.MULTILINE|re.DOTALL)
    res = []
    for match in matches.finditer(content):
        start = content[0:match.start()].count("\n")
        res.append(match.group(2))
    return res

def generate_song(song_info, file_name, contents, counter, archive):
    if song_info == None:
        return []
    body_list = merge_lists(
        get_verses(contents),
        get_choruses(contents),
        get_images(contents),
    )
    num = counter.get_count(file_name)
    return body_list

def merge_lists(v, c, i):
    l = []
    l.extend(v)
    l.extend(c)
    l.extend(i)
    return sorted(l, key=lambda x: x[0])

class Counter:
    def __init__(self, order):
        self.order = order
        self.count = len(order)
        self.last = 0
    def get_count(self, file_name):
        try:
            self.last = (self.order.index(file_name) + 1)
        except:
            self.last = self.count
            self.count += 1
        return self.last

if __name__ == "__main__":
    json_res = {}
    if (not ARCHIVE_PATH.exists()):
        get_songbook(ARCHIVE_PATH)
    with zipfile.ZipFile(ARCHIVE_PATH, mode="r") as archive:
        c = get_file_contents(archive, "sangbog-main/booklet/main.tex").decode('UTF-8')
        counter = Counter(get_song_order(c))
        songs = list(filter(
            lambda x: x.filename.startswith("sangbog-main/sange") and not x.is_dir(),
            archive.infolist())
        )
        song_count = len(songs)
        count = 0
        for info in songs:
            count +=1
            percent = (count/song_count)*100
            sys.stdout.write("\rGenerating songbook %d%%" % (percent))
            sys.stdout.flush()
            contents = get_file_contents(archive, info.filename).decode('UTF-8')
            song_info = get_song_info(contents)
            print(song_info)
            song_body = generate_song(song_info, info.filename, contents, counter, archive)
            if song_body:
                json_res[counter.last] = {
                    "title": song_info[0],
                    "melody": song_info[1],
                    "body": song_body
                }

    print("\n\rWriting to json")
    with open(JSON_PATH, encoding="utf-8", mode="w") as f:
        f.write(json.dumps(json_res, ensure_ascii=False))
    print("\rRemoving archive")
    CWD.joinpath(ARCHIVE_PATH).unlink()
