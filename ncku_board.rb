require 'sinatra'
require 'date'

# 設定：開啟 Session 功能來記住使用者
enable :sessions
set :session_secret, 'this_is_a_very_long_secret_key_created_for_ncku_board_security_check_to_pass_the_requirement_of_sixty_four_bytes'
# --- 模擬資料庫 (存在記憶體中，重開機會清空) ---
TASKS = [
  { 
    id: 1, 
    title: "徵求微積分課本", 
    status: "等待救援", 
    reward: "一杯波哥", 
    content: "我的課本不見了，期末考急用！", 
    time: "2023-12-25", 
    publisher: "student1@gs.ncku.edu.tw",
    helper: nil 
  }
]

# --- 輔助方法 ---
helpers do
  # 檢查是否登入
  def check_login
    redirect '/' unless session[:user_email]
  end

  # 驗證是否為成大信箱
  def ncku_email?(email)
    email.match?(/@(gs\.)?ncku\.edu\.tw$/)
  end
end

# --- 路由區 (Controller) ---

# 1. 登入頁面
get '/' do
  erb :login
end

# 2. 處理登入邏輯
post '/login' do
  email = params[:email]
  if ncku_email?(email)
    session[:user_email] = email
    redirect '/tasks'
  else
    @error = "請使用成大信箱 (@gs.ncku.edu.tw 或 @ncku.edu.tw)"
    erb :login
  end
end

# 3. 公佈欄首頁 (Dashboard)
get '/tasks' do
  check_login
  @tasks = TASKS.reverse # 新的任務排前面
  erb :dashboard
end

# 4. 處理發佈新任務
post '/tasks' do
  check_login
  TASKS << {
    id: TASKS.size + 1,
    title: params[:title],
    status: "等待救援",
    reward: params[:reward],
    content: params[:content],
    time: Time.now.strftime("%Y-%m-%d"),
    publisher: session[:user_email],
    helper: nil
  }
  redirect '/tasks'
end

# 5. 任務詳細頁面
get '/tasks/:id' do
  check_login
  @task = TASKS.find { |t| t[:id] == params[:id].to_i }
  erb :task_detail
end

# 6. 接收任務 (我願意幫忙)
post '/tasks/:id/accept' do
  check_login
  task = TASKS.find { |t| t[:id] == params[:id].to_i }
  helper_email = params[:helper_email]
  
  # 更新任務狀態
  task[:status] = "已接收"
  task[:helper] = helper_email
  
  # 這裡模擬發送通知
  @flash_message = "🎉 通知已發送給 #{task[:publisher]}！告知您 (#{helper_email}) 願意幫忙。"
  @task = task
  erb :task_detail
end

# --- HTML 樣板區 (View) ---
__END__

@@layout
<!DOCTYPE html>
<html>
<head>
  <title>成大任務公佈欄</title>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif; background: #f0f2f5; margin: 0; padding-bottom: 80px; }
    .container { max-width: 600px; margin: 0 auto; padding: 20px; }
    .card { background: white; border-radius: 12px; padding: 20px; margin-bottom: 15px; box-shadow: 0 2px 5px rgba(0,0,0,0.05); transition: 0.2s; }
    .card:hover { transform: translateY(-2px); box-shadow: 0 5px 15px rgba(0,0,0,0.1); }
    .status-tag { display: inline-block; padding: 4px 10px; border-radius: 20px; font-size: 12px; font-weight: bold; }
    .status-open { background: #e6f7ff; color: #1890ff; }
    .status-closed { background: #f6ffed; color: #52c41a; }
    .input-group { margin-bottom: 15px; }
    input, textarea { width: 100%; padding: 12px; border: 1px solid #ddd; border-radius: 8px; box-sizing: border-box; font-size: 16px; margin-top: 5px; }
    .btn { width: 100%; padding: 12px; background: #B01F24; color: white; border: none; border-radius: 8px; font-size: 16px; cursor: pointer; }
    .btn-secondary { background: #666; }
    
    /* 右下角懸浮按鈕 (FAB) */
    .fab { position: fixed; bottom: 30px; right: 30px; width: 60px; height: 60px; background: #B01F24; border-radius: 50%; color: white; font-size: 30px; text-align: center; line-height: 60px; box-shadow: 0 4px 10px rgba(0,0,0,0.3); cursor: pointer; text-decoration: none; display: flex; align-items: center; justify-content: center; }
    
    /* 彈窗樣式 */
    .modal { display: none; position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: rgba(0,0,0,0.5); z-index: 999; }
    .modal-content { background: white; margin: 20% auto; padding: 20px; width: 80%; max-width: 400px; border-radius: 12px; }
    .header { background: #B01F24; color: white; padding: 15px; text-align: center; font-weight: bold; }
  </style>
  <script>
    function toggleModal() {
      var modal = document.getElementById('taskModal');
      modal.style.display = (modal.style.display === 'block') ? 'none' : 'block';
    }
  </script>
</head>
<body>
  <%= yield %>
</body>
</html>

@@login
<div class="container" style="text-align: center; margin-top: 100px;">
  <h1 style="color: #B01F24;">🔴 NCKU 任務牆</h1>
  <p>成大人的互助平台</p>
  
  <div class="card">
    <form action="/login" method="POST">
      <div class="input-group">
        <label style="text-align: left; display: block;">請輸入學校信箱驗證</label>
        <input type="email" name="email" placeholder="example@gs.ncku.edu.tw" required>
      </div>
      <% if @error %>
        <p style="color: red; font-size: 14px;"><%= @error %></p>
      <% end %>
      <button class="btn">驗證身分並進入</button>
    </form>
  </div>
</div>

@@dashboard
<div class="header">
  NCKU 公佈欄 (<%= session[:user_email] %>)
</div>

<div class="container">
  <% @tasks.each do |task| %>
    <a href="/tasks/<%= task[:id] %>" style="text-decoration: none; color: inherit;">
      <div class="card">
        <div style="display: flex; justify-content: space-between; align-items: start;">
          <h3 style="margin: 0 0 10px 0;"><%= task[:title] %></h3>
          <span class="status-tag <%= task[:status] == '等待救援' ? 'status-open' : 'status-closed' %>">
            <%= task[:status] %>
          </span>
        </div>
        <p style="color: #666; font-size: 14px; margin: 5px 0;">💰 報酬：<%= task[:reward] %></p>
        <p style="color: #888; font-size: 12px; margin: 0;">📅 發布於 <%= task[:time] %> by <%= task[:publisher].split('@').first %></p>
      </div>
    </a>
  <% end %>
</div>

<div class="fab" onclick="toggleModal()">+</div>

<div id="taskModal" class="modal">
  <div class="modal-content">
    <h3 style="text-align: center;">發布新任務</h3>
    <form action="/tasks" method="POST">
      <input type="text" name="title" placeholder="標題 (例：徵求計算機)" required>
      <input type="text" name="reward" placeholder="報酬 (例：一杯 50 嵐)" required>
      <textarea name="content" rows="4" placeholder="詳細內容..." required></textarea>
      <div style="margin-top: 15px; display: flex; gap: 10px;">
        <button type="button" class="btn btn-secondary" onclick="toggleModal()">取消</button>
        <button type="submit" class="btn">確認發布</button>
      </div>
    </form>
  </div>
</div>

@@task_detail
<div class="header">
  <a href="/tasks" style="color: white; float: left; text-decoration: none;">← 返回</a>
  任務詳情
</div>

<div class="container">
  <% if @flash_message %>
    <div style="background: #d4edda; color: #155724; padding: 15px; border-radius: 8px; margin-bottom: 20px;">
      <%= @flash_message %>
    </div>
  <% end %>

  <div class="card">
    <h2><%= @task[:title] %></h2>
    <span class="status-tag <%= @task[:status] == '等待救援' ? 'status-open' : 'status-closed' %>">
      <%= @task[:status] %>
    </span>
    <hr style="border: 0; border-top: 1px solid #eee; margin: 15px 0;">
    
    <p><strong>📝 內容：</strong><br><%= @task[:content] %></p>
    <p><strong>💰 報酬：</strong><%= @task[:reward] %></p>
    <p><strong>📧 發布者：</strong><%= @task[:publisher] %></p>
    <p><strong>📅 時間：</strong><%= @task[:time] %></p>
    
    <% if @task[:helper] %>
      <div style="background: #f9f9f9; padding: 10px; border-radius: 8px; margin-top: 15px;">
        ✅ <strong>接收者：</strong> <%= @task[:helper] %>
      </div>
    <% end %>
  </div>

  <% if @task[:status] == "等待救援" %>
    <div class="card">
      <h3>🤝 我願意幫忙！</h3>
      <form action="/tasks/<%= @task[:id] %>/accept" method="POST">
        <label>請輸入您的聯絡信箱，以便發布者聯繫您：</label>
        <input type="email" name="helper_email" placeholder="helper@ncku.edu.tw" required>
        <button class="btn" style="margin-top: 10px;">確認接收任務</button>
      </form>
    </div>
  <% end %>
</div>
