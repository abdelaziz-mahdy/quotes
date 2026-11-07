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
