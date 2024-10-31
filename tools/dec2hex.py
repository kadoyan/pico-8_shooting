
from flask import Flask, render_template, request, send_file
import pandas as pd
import io

app = Flask(__name__)

@app.route('/')
def index():
    return render_template('convert.html')

@app.route('/process_csv', methods=['POST'])
def process_csv():
    result_list = []
    file = request.files['file']
    if not file:
        return 'ファイルが選択されていません。'

    # CSVをデータフレームとして読み込み
    df = pd.read_csv(file, header=None, names=['Time', 'ID'], dtype=str)

    # 各行に対して処理
    def export_row(row):
        if pd.notnull(row['Time']) and pd.notnull(row['ID']):
            try:
                # Timeを3桁の16進数表記にする
                time_str = f"{int(row['Time'], 16):03X}"
                # IDを2桁の16進数表記にする
                id_str = f"{int(row['ID'], 16):02X}"
                
                result_list.append(f'{time_str}{id_str}')
            except ValueError:
                # エラー処理（数値として変換できない場合）
                return "エラー：16進数に変換できない値があります"
        else:
            pass
            
    df = df.apply(export_row, axis=1)
    
    # リストの内容をカンマ区切りで連結
    result = ','.join(result_list)
    
    # HTMLのテンプレートに渡してレンダリング
    return render_template('convert.html', result=result)
    


if __name__ == '__main__':
    app.run(debug=True, port=5001)
