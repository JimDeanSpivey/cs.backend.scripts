import redis
from datetime import datetime,timedelta
import argparse


def extractDate(key):
    key = key.split(':')[1:]
    dateStr = '-'.join(key)
    return datetime.strptime(dateStr, '%Y%m%d-%H%M')

def deleteLowCounts(key, wordCount):
    for kz in r.zrangebyscore(k, 1, wordCount):
        print 'deleting- ' +k+ ' : ' +kz
        r.zrem(k, kz)

parser = argparse.ArgumentParser(description='Process some integers.')
parser.add_argument('-a', '--age', help='How old the twitter word count, measured in hours.', required=True, type=int)
parser.add_argument('-c', '--wordCount', help='Word counts lower than this will be deleted.', required=True, type=int)
args = parser.parse_args()
age = args.age
wordCount = args.wordCount


r = redis.StrictRedis(host='localhost', port=6379, db=0)
keys = r.keys('*')
for k in keys:
    date = extractDate(k)

    #delete low word counts
    if date < datetime.now() - timedelta(hours=age):
        deleteLowCounts(k, wordCount)

