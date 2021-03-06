#!/usr/bin/python3

from lxml import html
from pathlib import Path
import requests
import sys


xpath = {
    'title': '//div[@class="problem-statement"]/div[@class="header"]//div[@class="title"]/text()',
    'tags': '//span[@class="tag-box"]/text()'
    }

problemset_url='https://codeforces.com/problemset/problem'


def fetch_tags(tree):
    tags = list(it.strip() for it in tree.xpath(xpath['tags']))
    return ', '.join(tags)


def fetch_title(tree):
    title = "".join(tree.xpath(xpath['title']))
    title = title[title.index(' '):].replace(' ', '')
    return title


def prepare_files(tree, url):
    from textwrap import dedent
    title = fetch_title(tree)
    statement_filename = "{}.statement.txt".format(title)
    solution_filename = "{}.solution.txt".format(title)
    tags = fetch_tags(tree)
    with open(statement_filename, 'w') as out:
        metadata = f"""\
        ---
        title: {title}
        tags: {tags}
        link: {url}
        ---
        
        """
        out.write(dedent(metadata))
#    Path(solution_filename).touch() This doesn't seem to be very useful.


if __name__ == '__main__':
    if not (len(sys.argv) - 1):
        print("Provide a CF problem URL!")
        exit(-1)

    prob = sys.argv[1].upper()
    url = f'{problemset_url}/{prob[:-1]}/{prob[-1]}'
    page = requests.get(url)
    tree = html.fromstring(page.content)

    prepare_files(tree, url)


