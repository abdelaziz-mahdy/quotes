from flask import Flask , request , jsonify,json
from bs4 import BeautifulSoup
import requests
import random
from concurrent.futures import ThreadPoolExecutor, as_completed
from time import time

app = Flask(__name__)


#bucketName = app_identity.get_default_gcs_bucket_name()
#fileName = "/" + bucketName + "/Data/Data.txt"
DataFileName="Data.txt"
Data_countFileName="DataCount.txt"
DataFileName_preview="Data_preview.txt"
Data_countFileName_preview="DataCount_preview.txt"

class brainyquote:
    endlist = []
    All_topics = []
    topics = []
    pages=[1,2,3,4,5,6,7,8,9,10]
    choice=5
    def __init__(self, _choice, _pages): 
        self.choice = _choice
        self.pages=_pages
    #retrives the Popular topics from the site
    url_topics = 'https://www.brainyquote.com/topics'
    url_qoutes = 'https://www.brainyquote.com'
    def GetTopics(self):
        content = requests.get(self.url_topics).content
        soup = BeautifulSoup(content, 'html.parser')
        quotes_topics_table = soup.find('div', {'class': 'row bq_left'})
        quotes_topics=quotes_topics_table.find_all('div', {'class': 'bqLn'})
        for i in quotes_topics:
            tmp=(i.text).strip()
            self.All_topics.append(tmp)
        print(self.All_topics)
        self.topics=RemoveDuplicates(self.All_topics)
    
    def WriteToFile(self):
        #print("Saving To DB")
        #SaveToDB(mylist)
        #SaveToFirebaseDB(mylist)
        print("Saving To file")
        self.mylist=RemoveDuplicates(self.endlist)
        if(self.choice==1):
            SaveToFile_Append(self.mylist)
        elif(self.choice==0):
            SaveToFile_Rewrite(self.mylist)
    def GetQoutesFromBrainyQuote(self,Topic):
        for N in self.pages:
            #selects a random topic and search for quotes
            query=Topic
            search ='/topics/'+query+'-quotes'+'_'+str(N)
            ready_uri = self.url_qoutes + search
            print(ready_uri)
            print("Pages remaining: "+str(len(self.pages)-self.pages.index(N)))
            content = requests.get(ready_uri).content
            soup = BeautifulSoup(content, 'html.parser')
            quotes_text = soup.find_all('a', {'class': 'b-qt'})
            quotes_author = soup.find_all('a', {'class': 'bq-aut'})
        
            for i,y in zip(quotes_text,quotes_author):
                d={}
                d['quote'] = i.text
                d['author'] = y.text
                d['topic'] = Topic
                self.endlist.append(d)
    def Run(self):
        self.GetTopics()
        processes = []
        with ThreadPoolExecutor(max_workers=10) as executor:
            for T in self.topics:
                print("Topics remaining: "+str(len(self.topics)-self.topics.index(T)))
                processes.append(executor.submit(self.GetQoutesFromBrainyQuote, T))

        for task in as_completed(processes):
            print(task.result())
        self.WriteToFile()
        return self.mylist
@app.route('/brainyquote_get_all')
def fill():
    choice=int(input("1 for append \n0 for rewrite"))
    pg=int(input("number of pages"))
    pages=list(range(1, pg+1))
    print(pages)
    print(choice)
    start=brainyquote(choice,pages)
    start1 = time()
    mylist=start.Run()
    print(f'Time taken: {time() - start1}')
    return jsonify(mylist)
def RemoveDuplicates(list_with_duplicates):
        New_List=[]
        for i in list_with_duplicates:
            if i not in New_List: 
                New_List.append(i) 
        return New_List
def SaveToFile_Rewrite(results):
    try:
        with open(DataFileName, 'w') as outfile:
            json.dump(results, outfile)
    except Exception as ex:
        print("Something went wrong: {}1".format(ex))
    #print(results)
    try:
        with open(Data_countFileName, 'w') as outfile:
            outfile.write(str(len(results)))
        
    except Exception as ex:
        print("Something went wrong: {}2".format(ex))    
    random.shuffle(results)
    try:
        with open(DataFileName_preview, 'w') as outfile:
            json.dump(results[1:500], outfile)
    except Exception as ex:
        print("Something went wrong: {}1".format(ex))
    #print(results)
    try:
        with open(Data_countFileName_preview, 'w') as outfile:
            outfile.write(str(len(results[1:500])))
        
    except Exception as ex:
        print("Something went wrong: {}2".format(ex))    
    return jsonify(results)

def SaveToFile_Append(results):
    data=[]
    ##reading the old data file
    try:
        with open(DataFileName, 'r') as outfile:
            data=json.load(outfile)
        
    except Exception as ex:
        print("Something went wrong: {}1".format(ex))
    #try:
        #with open(Data_countFileName, 'r') as outfile:
            #count=int(outfile.readline())
            
        #print(count)
    #except Exception as ex:
        #print("Something went wrong: {}2".format(ex))   
        
    data.extend(results)
    print(len(data))
    data=RemoveDuplicates(data)
    print(len(data))
    #writing the new data file
    try:
        
        with open(DataFileName, 'w') as outfile:
            json.dump(data, outfile)
    except Exception as ex:
        print("Something went wrong: {}3".format(ex))
     #writing the new data file-count
    try:
        with open(Data_countFileName, 'w') as outfile:
            outfile.write(str(len(data)))
    except Exception as ex:
        print("Something went wrong: {}4".format(ex))    
    #print(results)
    #writing the new data file-preview
    random.shuffle(data)
    try:
        with open(DataFileName_preview, 'w') as outfile:
            json.dump(data[1:500], outfile)
    except Exception as ex:
        print("Something went wrong: {}1".format(ex))
    #print(results)
    #writing the new data file-preview-count
    try:
        with open(Data_countFileName_preview, 'w') as outfile:
            outfile.write(str(len(data[1:500])))
        
    except Exception as ex:
        print("Something went wrong: {}2".format(ex))
   
    return jsonify(results)
@app.route('/see_saved_local')
def seeSavedLocal():
    data=[]
    try:
        with open(DataFileName, 'r') as outfile:
            data=json.load(outfile)
    except Exception as ex:
        print("Something went wrong: {}".format(ex))
    #print(results) 
    return jsonify(data)

@app.route('/see_saved_local_count')
def seeSavedLocalCount():
    try:
        with open(Data_countFileName, 'r') as outfile:
            count=int(outfile.readline())
    except Exception as ex:
        print("Something went wrong: {}2".format(ex))    
    return jsonify(count)
@app.route('/see_saved_local_preview')
def seeSavedLocalPreview():
    data=[]
    try:
        with open(DataFileName_preview, 'r') as outfile:
            data=json.load(outfile)
    except Exception as ex:
        print("Something went wrong: {}".format(ex))
    #print(results) 
    return jsonify(data)
@app.route('/see_saved_local_preview_count')
def seeSavedLocalPreviewCount():
    try:
        with open(Data_countFileName_preview, 'r') as outfile:
            count=int(outfile.readline())
    except Exception as ex:
        print("Something went wrong: {}2".format(ex))    
    return jsonify(count)
@app.route('/see_saved_online')
def seeSavedOnline():
    content_data=[]
    try:
        uri = 'https://storage.googleapis.com/my-qoutes-app-123456.appspot.com/Data.txt'
        content = requests.get(uri).content
    except Exception as ex:
        print("Something went wrong: {}".format(ex))
    #print(results)
    return content
@app.route('/see_saved_online_count')
def seeSavedOnlineCount():
    content_count=[]
    try:
        uri = 'https://storage.googleapis.com/my-qoutes-app-123456.appspot.com/DataCount.txt'
        content = requests.get(uri).content
    except Exception as ex:
        print("Something went wrong: {}".format(ex))
    #print(results)
    return content
@app.route('/see_saved_online_preview')
def seeSavedOnline_preview():
    content_data=[]
    try:
        uri = 'https://storage.googleapis.com/my-qoutes-app-123456.appspot.com/Data_preview.txt'
        content = requests.get(uri).content
    except Exception as ex:
        print("Something went wrong: {}".format(ex))
    #print(results)
    return content
@app.route('/see_saved_online_count_preview')
def seeSavedOnlineCount_preview():
    content_count=[]
    try:
        uri = 'https://storage.googleapis.com/my-qoutes-app-123456.appspot.com/DataCount_preview.txt'
        content = requests.get(uri).content
    except Exception as ex:
        print("Something went wrong: {}".format(ex))
    #print(results)
    return content


if __name__ == '__main__':
    app.run(port=5000)

#import firebase_admin
#from firebase_admin import credentials
#from firebase_admin import firestore

#def SaveToFirebaseDB(tmp):
    #cred = credentials.Certificate('qoutesapp-75edc-ac88d67222f8.json')
    #firebase_admin.initialize_app(cred)
    #db = firestore.client()
    #doc_ref = db.collection(u'qoutes')
    #try:
        #for i in tmp:
            #print("Items remaining: "+str(len(tmp)-tmp.index(i)))
            #print(i)
            #doc_ref.add(i)
    #except Exception as ex:
            #print("Something went wrong: {}".format(ex))
#@app.route('/see_fb_db') 
#def ReadFirebaseDB():
    #db = firestore.client()
    #qoutes_ref = db.collection(u'qoutes')
    #docs = qoutes_ref.stream()
    #mylist=[]
    #for doc in docs:
        #print(f'{doc.id} => {doc.to_dict()}')
        #mylist.append(doc.to_dict())
    #return jsonify(mylist)

#from flask_mysqldb import MySQL 

#app.config['MYSQL_USER'] = 'sql2367531'
#app.config['MYSQL_PASSWORD'] = 'aK6%nM7*'
#app.config['MYSQL_HOST'] = 'sql2.freemysqlhosting.net'
#app.config['MYSQL_DB'] = 'sql2367531'
#app.config['MYSQL_CURSORCLASS'] = 'DictCursor'

#mysql = MySQL(app)
#def SaveToDB(tmp):
#    try:
#        cur = mysql.connection.cursor()
#        for i in tmp:
#            print("Items remaining: "+str(len(tmp)-tmp.index(i)))
#            sql = "INSERT INTO example (author, quote, topic) VALUES (%s, %s, %s)"
#            val = (i['author'], i['quote'],i['topic'])
#            cur.execute(sql, val)
#        mysql.connection.commit()
#    except Exception as ex:
#        print("Something went wrong: {}".format(ex))
#    finally:
#        print("closing connection")
#        cur.close()
#        print("Done closing connection")
    
#@app.route('/delete_table')
#def DeleteTable():
#    try:
#        cur = mysql.connection.cursor()
#        Delete_Table = """DROP TABLE example """
#        cur.execute(Delete_Table)
#        mysql.connection.commit()
#    except Exception as ex:
#        print("Something went wrong: {}".format(ex))
#    finally:
#        print("closing connection")
#        cur.close()
#        print("Done closing connection")
#    return "deleted"
#@app.route('/empty_rows')
#def FreeTable():
#    try:
#        cur = mysql.connection.cursor()
#        Delete_all_rows = """truncate table example """
#        cur.execute(Delete_all_rows)
#        mysql.connection.commit()
#    except Exception as ex:
#        print("Something went wrong: {}".format(ex))
#    finally:
#        print("closing connection")
#        cur.close()
#        print("Done closing connection")
#    return "All table rows got deleted"
#@app.route('/see_db')
#def seeDB():
#    try:
#        cur = mysql.connection.cursor()
#        cur.execute('''SELECT * FROM example''')
#        results = cur.fetchall()
#    except Exception as ex:
#        print("Something went wrong: {}".format(ex))
#    finally:
#        print("closing connection")
#        cur.close()
#        print("Done closing connection")
#    #print(results)
#    return jsonify(results)
#@app.route('/see_db_save')
#def seeDB_Save():
#    try:
#        cur = mysql.connection.cursor()
#        cur.execute('''SELECT * FROM example''')
#        results = cur.fetchall()
#        SaveToFile_Append(results)
#    except Exception as ex:
#        print("Something went wrong: {}".format(ex))
#    finally:
#        print("closing connection")
#        cur.close()
#        print("Done closing connection")
#    #print(results)
#    return jsonify(results)
##http://127.0.0.1:5000/GetQuotesByTopicFromDB/?topic=work
#@app.route('/GetQuotesByTopicFromDB/',methods=['GET'])
#def GetQuotesByTopicFromDB():
#    try:
#        query = str(request.args['topic'])
#        cur = mysql.connection.cursor()
#        sql='''SELECT * FROM example where topic = %s'''
#        cur.execute(sql, (query,))
#        results = cur.fetchall()
#    except Exception as ex:
#        print("Something went wrong: {}".format(ex))
#    finally:
#        print("closing connection")
#        cur.close()
#        print("Done closing connection")
#    #print(results)
#    return jsonify(results)

#@app.route('/getdbtopics')
#def GetDBTopics():
#    try:
#        cur = mysql.connection.cursor()
#        sql='''SELECT DISTINCT topic FROM example'''
#        cur.execute(sql)
#        results = cur.fetchall()
#        SaveToFile_Append(results)
#    except Exception as ex:
#        print("Something went wrong: {}".format(ex))
#    finally:
#        print("closing connection")
#        cur.close()
#        print("Done closing connection")
#    #print(results)
#    return jsonify(results)

#@app.route('/gettopics')
#def GetTopics():
#    All_topics = []
    
#    #retrives the Popular topics from the site
#    uri = 'https://www.brainyquote.com/topics'
#    content = requests.get(uri).content
#    soup = BeautifulSoup(content, 'html.parser')
#    quotes_topics_table = soup.find('div', {'class': 'row bq_left'})
#    quotes_topics=quotes_topics_table.find_all('div', {'class': 'bqLn'})
#    for i in quotes_topics:
#        tmp=(i.text).strip()
#        All_topics.append(tmp)
#    print(All_topics)
#    topics = [] 
#    for i in All_topics:
#        if i not in topics:
#            topics.append(i) 
#    endlist=[]
#    for i in topics:
#        d={}
#        d['topic'] = i
#        endlist.append(d)
#    return jsonify(endlist)
##http://127.0.0.1:5000/getquotes/?topic=work
#@app.route('/getquotes/',methods=['GET'])
#def GetQuotesByTopic():
#    endlist=[]
#    pages=[1,2]
#    query = str(request.args['topic'])
#    uri = 'https://www.brainyquote.com'
#    for N in pages:
#        #selects a random topic and search for quotes
#        search ='/topics/'+query+'-quotes'+'_'+str(N)
#        ready_uri = uri + search
#        print(ready_uri)
#        print("Pages remaining: "+str(len(pages)-pages.index(N)))
#        content = requests.get(ready_uri).content
#        soup = BeautifulSoup(content, 'html.parser')
#        quotes_text = soup.find_all('a', {'class': 'b-qt'})
#        quotes_author = soup.find_all('a', {'class': 'bq-aut'})
        
#        for i,y in zip(quotes_text,quotes_author):
#            d={}
#            d['quote'] = i.text
#            d['author'] = y.text
#            d['topic'] = query
#            endlist.append(d)
            
#    print(endlist)
    
#    mylist = [] 
#    for i in endlist:
#        if i not in mylist: 
#            mylist.append(i)
    
#    return jsonify(mylist)






#@app.route('/')
#def createDB():
#    try:
#        cur = mysql.connection.cursor()
#        cur.execute('''CREATE TABLE example (author VARCHAR(255), quote VARCHAR(255),topic VARCHAR(255),PRIMARY KEY (author, quote, topic))''')
        
#        return 'DB Created successfully'
#    except Exception as ex:
#        print("Something went wrong: {}".format(ex))
#    #cur.execute('''INSERT INTO example VALUES (1, 'Anthony')''')
#    #cur.execute('''INSERT INTO example VALUES (2, 'Billy')''')
#    #mysql.connection.commit()

#    #cur.execute('''SELECT * FROM example''')
#    #results = cur.fetchall()
#    #print(results)
#    #return str(results[1]['id'])

##http://127.0.0.1:5000/bysearch/?query=whatever
#@app.route('/bysearch/',methods=['GET'])
#def API():
#    if request.method == 'GET':
#        uri = 'https://www.brainyquote.com'
#        query = str(request.args['query'])
#        print(query)
#        if " " in query:
#            query = str(query).replace(" ","+")
#        else:
#            pass

#        search = '/search_results?q=' + query

#        ready_uri = uri + search
#        print(ready_uri)
#        content = requests.get(ready_uri).content
#        soup = BeautifulSoup(content, 'html.parser')
#        quotes_text = soup.find_all('a', {'class': 'b-qt'})
#        quotes_author = soup.find_all('a', {'class': 'bq-aut'})
#        l = []
        
#        for i,y in zip(quotes_text,quotes_author):
#            d={}
#            d['quote'] = i.text
#            d['author'] = y.text
#            l.append(d)
            
#        print(l)
#        return jsonify(l)

#@app.route('/getlucky')
#def TestYourLuck():
#    #retrives the Popular topics from the site
#    uri = 'https://www.brainyquote.com'
#    content = requests.get(uri).content
#    soup = BeautifulSoup(content, 'html.parser')
#    quotes_topics_table = soup.find('table', {'id': 'allTopics'})
#    quotes_topics=quotes_topics_table.find_all('div', {'class': 'bqLn'})
#    l = []
#    for i in quotes_topics:
#        l.append(i.text)
#    print(l)


#    #selects a random topic and search for quotes
#    query=random.choice(l)

#    search = '/search_results?q=' + query
#    ready_uri = uri + search
#    print(ready_uri)
#    content = requests.get(ready_uri).content
#    soup = BeautifulSoup(content, 'html.parser')
#    quotes_text = soup.find_all('a', {'class': 'b-qt'})
#    quotes_author = soup.find_all('a', {'class': 'bq-aut'})
#    endlist = []
#    for i,y in zip(quotes_text,quotes_author):
#        d={}
#        d['quote'] = i.text
#        d['author'] = y.text
#        endlist.append(d)
            
#    print(endlist)
#    SaveToDB(endlist)
#    return jsonify(endlist)

#@app.route('/random')
#def RandomQuotes():
#    uri = 'http://www.quotationspage.com/random.php'
#    print(uri)
#    content = requests.get(uri).content
#    soup = BeautifulSoup(content, 'html.parser')
#    quotes_text = soup.find_all('dt', {'class': 'quote'})
#    quotes_author = soup.find_all('dd', {'class': 'author'})
#    l = []
        
#    for i,y in zip(quotes_text,quotes_author):

#        d={}
#        d['quote'] = i.text
#        d['author'] = y.text
#        l.append(d)
  
#    print(l)
#    return jsonify(l)

