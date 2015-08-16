import redis
from datetime import datetime,timedelta

def extractDate(key):
    key = key.split(':')[1:]
    dateStr = '-'.join(key)
    return datetime.strptime(dateStr, '%Y%m%d-%H%M')

r = redis.StrictRedis(host='localhost', port=6379, db=0)

keys = r.keys('*')
for k in keys:
    print k
    date = extractDate(k)
    
    #delete low word counts
    if date < datetime.now() - timedelta(hours=24):
        print 'old enough'
        for kz in r.zrangebyscore(k, 1, 5):
            print 'deleting- ' +k+ ' : ' +kz
            r.zrem(k, kz)

    #TODO: maybe archive month old keywords?

