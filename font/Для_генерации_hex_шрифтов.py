def bintohex(sr):
    hexstr = ['0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F']
    a = int(sr, 2)
    return hexstr[a]


f = open('/home/victor/Documents/monody.csv', 'r')
str_arr = f.read().split('\n')
f.close()

f = open('/home/victor/Documents/monody.hex', 'w')
arr = []
for i in range(128):
    arr.append(str_arr[i].split(','))
#Arr - двухмерный массив
    
for i in range(0,128,8): #бег по строкам
    for j in range(0,128,8): #бег по столбцам
        for k in range(8):    
            sr = arr[i+k][j+0]+arr[i+k][j+1]+arr[i+k][j+2]+arr[i+k][j+3]
            f.write(bintohex(sr))
            sr = arr[i+k][j+4]+arr[i+k][j+5]+arr[i+k][j+6]+arr[i+k][j+7]
            f.write(bintohex(sr))

f.close()