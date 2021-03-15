---
title: "银行业务管理系统\n系统设计与实现报告"
tagline: "中科大 2020 年春季数据库课程的大实验"
excerpt: "“银行业务管理系统”是中科大 2020 年春季数据库课程的大实验"
tags: study-notes
header:
  actions:
    - label: "<i class='fab fa-github'></i> GitHub"
      url: https://github.com/iBug/Junk-Bank-System
image_prefix: "https://ibug.github.io/Junk-Bank-System/image"
---

## 1 概述

本项目使用 [Ruby on Rails](https://rubyonrails.org/) 实现了一个简易的银行业务管理系统，已于 GitHub 开源，地址为 <https://github.com/iBug/Junk-Bank-System>。另外本项目还[发布在了 Docker Hub 上](https://hub.docker.com/repository/docker/ibugone/junk-bank-system)（镜像为 `ibugone/junk-bank-system`），并据此实现了使用 [Docker Compose](https://docs.docker.com/compose/) 的简易部署，其配置文件位于 <https://github.com/iBug/Junk-Bank-System/blob/master/docker-compose.yml>。

### 1.1 系统目标

某银行准备开发一个银行业务管理系统，要求实现**客户管理**、**账户管理**、**贷款管理**与**业务统计**四大类功能。详细需求在 1.2.2 节介绍。

### 1.2 需求说明

#### 1.2.1 数据需求

银行有多个支行。各个支行位于某个城市，每个支行有唯一的名字。银行要监控每个支行的资产。 银行的客户通过其身份证号来标识。银行存储每个客户的姓名、联系电话以及家庭住址。为了安全起见，银行还要求客户提供一位联系人的信息，包括联系人姓名、手机号、Email 以及与客户的关系。客户可以有帐户，并且可以贷款。客户可能和某个银行员工发生联系，该员工是此客户的贷款负责人或银行帐户负责人。银行员工也通过身份证号来标识。员工分为部门经理和普通员工，每个部门经理都负责领导其所在部门的员工，并且每个员工只允许在一个部门内工作。每个支行的管理机构存储每个员工的姓名、电话号码、家庭地址、所在的部门号、部门名称、部门类型及部门经理的身份证号。银行还需知道每个员工开始工作的日期，由此日期可以推知员工的雇佣期。银行提供两类帐户：储蓄帐户和支票帐户。帐户可以由多个客户所共有，一个客户也可开设多个账户，但在一个支行内最多只能开设一个储蓄账户和一个支票账户。每个帐户被赋以唯一的帐户号。银行记录每个帐户的余额、开户日期、开户的支行名以及每个帐户所有者访问该帐户的最近日期。另外，每个储蓄帐户有利率和货币类型，且每个支票帐户有透支额。每笔贷款由某个分支机构发放，能被一个或多个客户所共有。每笔贷款用唯一的贷款号标识。银行需要知道每笔贷款所贷金额以及逐次支付的情况（银行将贷款分几次付给客户）。虽然贷款号不能唯一标识银行所有为贷款所付的款项，但可以唯一标识为某贷款所付的款项。对每次的付款需要记录日期和金额。

#### 1.2.2 功能需求

- **客户管理**：提供客户所有信息的增、删、改、查功能；如果客户存在着关联账户或者贷款记录，则不允许删除；
- **账户管理**：提供账户开户、销户、修改、查询功能，包括储蓄账户和支票账户；账户号不允许修改；
- **贷款管理**：提供贷款信息的增、删、查功能，提供贷款发放功能；贷款信息一旦添加成功后不允许修改；要求能查询每笔贷款的当前状态（未开始发放、发放中、已全部发放）；处于发放中状态的贷款记录不允许删除；
- **业务统计**：按业务分类（储蓄、贷款）和时间（月、季、年）统计各个支行的业务总金额和用户数，要求对统计结果同时提供表格和曲线图两种可视化展示方式。

#### 1.2.3 需求说明

1. 支行、部门和员工的信息需要预先插入到数据库中，本项目假设这三类数据已经在数据库中了，并且本实验不要求实现这三类数据的维护。
2. 后台 DBMS 使用 MySQL；
3. 前端开发工具不限，可以是 C/S 架构也可以是 B/S 架构；
4. 查询功能允许自行设计，但要求尽可能灵活设计，考虑用户多样化的查询需求；
5. 各类数据的类型可自行根据实际情况设计；
6. 测试数据自行设计；
7. 系统实现时要保证数据之间的一致性；
8. 程序须有一定的出错处理，要求自己先做好测试，能够处理可以预见的一些错误，例如输入的客户姓名带单引号（类似 `O'Neil`）、输入数据不合法等等；
9. 其余功能可以自行添加，例如登录管理、权限管理等等，但不做强制要求。如果做了添加，请在实验报告中加以描述；
10. 本实验要求单独完成。

### 1.3 本报告的主要贡献

众所周知，好的实验报告是成功实验的一半。因此

- 本报告的主要贡献在于完整、详实、丰富地填满了这份繁杂冗长的实验报告模板，尽自己所能**充实**了各位助教阅读实验报告的体验。
- 其次，本报告介绍了一个采用良好开发技术达到 1.1 节所述目标、完成 1.2 节所述需求的 B/S 架构的银行业务管理系统，并对其代码及实现技巧进行了详细的剖析
- 另外，本报告通过详细的分析，介绍了 Ruby on Rails 框架的强大与便捷
- 最后，本报告在第 5 章为实验及实验报告的设计提出了一些改进意见。

## 2 总体设计

系统采用 [Ruby on Rails](https://rubyonrails.org/) 框架，使用 Model-View-Controller 架构进行前后端一体的全栈开发，前端采用 [Bootstrap 4](https://getbootstrap.com/docs/4.5/) 进行界面设计与优化，并使用 JavaScript 与 [jQuery](https://jquery.com/) 实现页面上的动态功能。

### 2.1 系统模块结构

本系统采用标准的 Ruby on Rails 全找开发结构，其结构如下图所示：

![image]({{ page.image_prefix }}/2.1.png)

各模块功能：

- Puma Server 负责处理客户端（浏览器）发来的 HTTP 请求，解析内容，并根据路由规则选择合适的控制器和动作，以及向客户端返回 HTTP 响应
- Controller (Action Controller) 负责执行实际的业务逻辑，包括调用模型与数值计算等
- Model (Active Record) 为 ORM，负责与数据库通信，从数据库内容构建 Ruby 模型供其他模块使用
- View (Action View) 负责从模板渲染 HTML 页面，交由 Server 返回
- MySQL 或 MariaDB 为后端 DBMS，负责数据的存储与维护等

模块之间的接口：

- 五个模块组成应用程序整体，通过 HTTP 协议与外部通信
- Server 通过直接调用 Action Controller 中相关方法的方式执行动作，通过外部变量 `params` 传输 HTTP 请求参数（包括 URL 参数与 POST 方式的主体）
- MySQL 与 Active Record 通过 SQL 查询的方式通信。AR 维护一个 SQL 客户端，通过其发送 SQL 语句及接收结果
- Active Record，Action Controller 与 Action View 之间均通过传递 Ruby 对象的方式传输数据

具体的 Active Record 模型、Action Controller 控制器与 Action View 视图在第 3 节介绍。

### 2.2 系统工作流程

系统工作流程如 2.1 节的图中所示，客户端（浏览器）访问网站时实际发生的工作流程按 2.1 节的图中逆时针进行，文字过程如下：

1. 浏览器向服务器发送 web 请求；
2. 服务器（此处忽略前端 Nginx / Apache 等反向代理服务器）根据定义好的路由（Routes）决定该请求要交给哪个控制器处理；
3. 控制器接收到请求，处理请求参数，根据请求内容存取所需的数据（对象模型）；
4. 应用程序模型（Active Record）根据接收到的查询请求构造 SQL 语句，向 DBMS 服务器进行查询，将查询结果转换为 Ruby 模型，返回给调用者；
5. 控制器完成规定的操作，获取了需要的数据，将它们发送给视图（View）控制器，视图控制器将 HTML 模板渲染成完整的 HTML 页面，传回给前端服务器；
6. 前端服务器将 HTML 页面作为 web 响应发送给浏览器。

### 2.3 数据库设计

数据库一共 12 个表，存储了各种实体（如账户）与实体之间的关系（如客户与账户的联系）。由于部分实验要求，如使用「名称」、「身份证号」之类的属性作为主键等对数据库设计以及 Active Record 的默认行为不够友好，因此本系统实现时全部使用自增整数 ID 作为主键，实验要求中的主键全部加上 `UNIQUE NOT NULL` 约束保持候选性质，按照普通属性处理。另外 Active Record 会主动记录每个项（数据表行）的创建与更改时间，因此每个表都有两个额外的时间列（由 `t.timestamps` 创建），与本实验无关，可以放心忽略。

下面为本实验所构建数据库模型的 ER 图：

![image]({{ page.image_prefix }}/er.png)

下面为创建每个表及相关约束所使用的 Active Record 迁移脚本。

#### 2.3.1 支行

```ruby
class CreateBranches < ActiveRecord::Migration[6.0]
  def change
    create_table :branches, comment: '支行' do |t|
      t.string :name, limit: 64, unique: true, comment: '名称'
      t.string :city, limit: 64, comment: '城市'
      t.decimal :assets, precision: 12, scale: 2, default: 0.0, comment: '资产'

      t.timestamps
    end
  end
end
```

每个支行具有三个属性：

- 名称，是唯一的
- 所在城市
- 资产

考虑到资产为金钱，因此使用两位定点小数存储。下面所有的「金额」属性相同处理。

#### 2.3.2 部门

```ruby
class CreateDepartments < ActiveRecord::Migration[6.0]
  def change
    create_table :departments, comment: '部门' do |t|
      t.string :name, limit: 64, unique: true, comment: '部门名称'
      t.string :kind, limit: 64, comment: '部门类型'

      t.timestamps
    end
  end
end
```

每个部门具有两个属性：

- 部门名称，是唯一的
- 部门类型

其中部门类型在实验要求中并未详细说明，因此本实现将其当作字符串，灵活度较高。

#### 2.3.3 员工

```ruby
class CreateStaffs < ActiveRecord::Migration[6.0]
  def change
    create_table :staffs, comment: '员工' do |t|
      t.string :person_id, limit: 18, unique: true, null: false, comment: '身份证号'
      t.string :name, limit: 64, comment: '姓名'
      t.string :phone, limit: 64, comment: '电话'
      t.string :address, limit: 256, comment: '家庭地址'
      t.date :start_date, default: 'CURRENT_TIMESTAMP', comment: '开始工作日期'
      t.boolean :manager, default: -> { false }, comment: '经理'

      t.references :branch, index: true, foreign_key: { on_delete: :restrict }
      t.references :department, index: true, foreign_key: { on_delete: :restrict }

      t.timestamps
    end
  end
end
```

每个员工具有八个属性：

- 身份证号，是唯一的
- 姓名
- 电话号码
- 家庭住址
- 开始工作的日期
- 是否是部门经理
- 所属支行
- 所属部门

其中所属支行和部门采用 `t.references` 方法创建，该方法会自动创建一个 `table_id` 列和一个外键索引（由 `index: true` 指定）。同时这里设置了 `on_delete: :restrict`，表示当支行或部门有从属员工时禁止删除。

#### 2.3.4 客户

```ruby
class CreateClients < ActiveRecord::Migration[6.0]
  def change
    create_table :clients, comment: '客户' do |t|
      t.string :person_id, limit: 18, unique: true, null: false, comment: '身份证号'
      t.string :name, limit: 64, comment: '姓名'
      t.string :phone, limit: 64, comment: '电话'
      t.string :address, limit: 256, comment: '地址'

      t.references :manager, null: true, index: true, foreign_key: { to_table: :staffs, on_delete: :restrict }
      t.integer :manager_type, limit: 1, default: 0, null: true

      t.timestamps
    end
  end
end
```

每个客户具有六个属性：

- 身份证号，是唯一的
- 姓名
- 电话号码
- 家庭住址
- 发生联系的员工（负责人）
- 负责人类型（账户负责人 / 贷款负责人 / 两者皆是）

每位客户还有一位联系人。出于实体独立性的考虑，联系人存在一张单独的表中，且该表使用客户 ID 作为主键（外键作主键），详细信息在 2.3.5 节介绍。

每位客户还有一个或多个账户。根据实验要求，一个客户在一个支行只能开设每种类型的账户各一个，因此另外开一个表，对 $(客户,支行,账户类型)$ 加上唯一索引，详细信息在 2.3.7 节介绍。

#### 2.3.5 客户的联系人

```ruby
class CreateContacts < ActiveRecord::Migration[6.0]
  def change
    create_table :contacts, id: false, comment: '联系人' do |t|
      t.string :name, limit: 64, comment: '姓名'
      t.string :phone, limit: 64, comment: '电话'
      t.string :email, limit: 64, comment: 'Email'
      t.string :relationship, limit: 64, comment: '与客户关系'
      t.references :client, primary_key: true, index: true, foreign_key: { on_delete: :cascade }

      t.timestamps
    end
  end
end
```

每个联系人有五个属性：

- 姓名
- 电话
- Email
- 与客户关系
- 关联的客户

该表没有独立的 ID 列（由 `create_table` 的参数 `id: false` 指定），使用 `client_id` 作主键（由 `t.references :client` 的 `primary_key: true` 指定）。每个联系人有一位关联客户，且当关联客户删除时联系人也一并删除（由 `t.references :client` 的 `on_delete: :cascade` 指定）。

#### 2.3.6 账户

```ruby
class CreateAccounts < ActiveRecord::Migration[6.0]
  def change
    create_table :accounts, comment: '账户' do |t|
      t.references :branch, index: true, foreign_key: { on_delete: :restrict }, comment: '开户支行'
      t.references :accountable, null: false, polymorphic: true, comment: '类型账户ID'
      t.decimal :balance, precision: 12, scale: 2, default: 0.0, comment: '余额'
      t.date :open_date, default: 'CURRENT_TIMESTAMP', comment: '开户日期'

      t.timestamps
    end
  end
end
```

每个账户有四个属性：

- 所属支行
- 账户类型及类型特定信息
- 余额
- 开户日期

其中 `t.references :accountable` 表示账户类型以及类型特定的额外信息（如储蓄账户的利率和货币类型以及支票账户的透支额等），使用 Active Record 的[多态关系 (Polymorphic Association)](https://guides.rubyonrails.org/association_basics.html#polymorphic-associations) 实现（由 `polymorphic: true` 指定），实际在数据库中记录为 `accountable_id` 和 `accountable_type` 两列，`accountable_id` 对应目标表的 ID 列为外键；`accountable_type` 为字符串，表示多态的具体类型，Active Record 根据该列决定要将哪个表作为关联表。该多态关系的两个具体类型：储蓄账户和支票账户分别在 2.3.8 节和 2.3.9 节详细介绍。

每个账户还有一个或多个客户为所有者。根据实验要求，一个客户在一个支行只能开设每种类型的账户各一个，因此另外开一个表，对 $(客户,支行,账户类型)$ 加上唯一索引，详细信息在 2.3.7 节介绍。

#### 2.3.7 客户账户关系

```ruby
class CreateOwnerships < ActiveRecord::Migration[6.0]
  def change
    # (Client, Branch, AccountType) -> Account
    create_table :ownerships, comment: '客户账户关系' do |t|
      t.references :account, foreign_key: { on_delete: :cascade }
      t.references :client, foreign_key: { on_delete: :restrict }
      t.references :branch, foreign_key: { on_delete: :restrict }
      t.string :accountable_type
      t.datetime :last_access, default: -> { 'CURRENT_TIMESTAMP' }, comment: '最近访问'

      t.timestamps
    end
  end
end
```

每个客户账户关系有五个属性：

- 关联的账户
- 关联的客户
- 关联的支行
- 账户类型
- 最近访问时间

该表的主要目的是实现实验要求中「一个客户在一个支行内最多只能开设一个储蓄账户和一个支票账户」一项，同时记录「每个帐户所有者访问该帐户的最近日期」。

其中关联的支行和账户类型为账户中的信息，但是为了实现开设账户的约束，需要对元组 $(客户,支行,账户类型)$ 加上唯一索引（unique index），因此将这两列信息也加入本表。

同时与本表关联的还有一个索引，其内容和意义如上所述。代码如下：

```ruby
class AddIndexToOwnerships < ActiveRecord::Migration[6.0]
  def change
    add_index :ownerships, %i[branch_id accountable_type client_id], unique: true
  end
end
```

#### 2.3.8 储蓄账户（多态关联）

```ruby
class CreateDepositAccounts < ActiveRecord::Migration[6.0]
  def change
    create_table :deposit_accounts, comment: '储蓄账户' do |t|
      t.float :interest_rate, default: 1.0, comment: '利率'
      t.string :currency, limit: 3, default: 'BTC', comment: '货币类型'
    end
  end
end
```

每个储蓄账户在账户的基础上有两个额外属性：

- 利率
- 货币类型

其中利率并非「金额」，因此采用浮点数存储；货币类型根据 ISO 4217 标准存储为 3 位大写字母，其中「3 位大写字母」由 Active Record 模型进行验证，而不是在数据库中验证，详细信息在 3.1 节介绍。

#### 2.3.9 支票账户（多态关联）

```ruby
class CreateCheckAccounts < ActiveRecord::Migration[6.0]
  def change
    create_table :check_accounts, comment: '支票账户' do |t|
      t.decimal :withdraw_amount, precision: 12, scale: 2, default: 0.0, comment: '透支额'
    end
  end
end
```

每个支票账户在账户的基础上有一个额外属性：

- 透支额

#### 2.3.10 贷款

```ruby
class CreateLoans < ActiveRecord::Migration[6.0]
  def change
    create_table :loans, comment: '贷款' do |t|
      t.decimal :amount, precision: 12, scale: 2, default: 0.0, comment: '金额'
      t.references :branch, index: true, foreign_key: { on_delete: :restrict }

      t.timestamps
    end
  end
end
```

每个贷款有两个属性：

- 所属支行
- 总金额

每个贷款还有一个或多个关联客户，采用普通的多对多关系，因此使用一张额外的表记录客户与贷款的关系，详细信息在 2.3.11 节中介绍。

#### 2.3.11 客户贷款关系

```ruby
class CreateClientsLoans < ActiveRecord::Migration[6.0]
  def change
    create_table :clients_loans do |t|
      t.references :loan, index: true, foreign_key: { on_delete: :cascade }
      t.references :client, index: true, foreign_key: { on_delete: :restrict }
    end
  end
end
```

每个客户贷款关系有两个属性：

- 关联贷款
- 关联客户

该表作为贷款——客户的多对多关系的中间表，没有额外属性。但是根据实验要求，贷款可以删除，但当客户有关联贷款时客户不能删除，所以该表的两个外键索引具有不同的 `on_delete` 设定。

#### 2.3.12 贷款发放

```ruby
class CreateIssues < ActiveRecord::Migration[6.0]
  def change
    create_table :issues, comment: '逐次支付' do |t|
      t.references :loan, index: true, foreign_key: { on_delete: :cascade }
      t.date :date, default: 'CURRENT_TIMESTAMP', comment: '日期'
      t.decimal :amount, precision: 12, scale: 2, default: 0.0, comment: '金额'
    end
  end
end
```

每个贷款发放有三个属性：

- 关联贷款
- 发放日期
- 发放金额

## 3 详细设计

### 3.1 Active Record 模型

#### 3.1.1 支行

```ruby
class Branch < ApplicationRecord
  has_many :staffs, dependent: :restrict_with_error
  has_many :ownerships, dependent: :restrict_with_error
  has_many :accounts, through: :ownerships
  has_many :loans, dependent: :restrict_with_error

  validates_uniqueness_of :name
  validates_presence_of :city
  validates_numericality_of :assets, greater_than_or_equal_to: 0.0
end
```

每个支行有多个员工、多个账户和多个贷款，使用 Active Record 的 `has_many` 定义关系，`dependent: :restrict_with_error` 指示当支行有关联项目时不允许删除。同时支行名称不能重复，所以加上唯一性验证（见 2.3.1 节）。剩下的支行城市验证非空，资产验证非负。

#### 3.1.2 部门

```ruby
class Department < ApplicationRecord
  has_many :staffs, dependent: :restrict_with_error

  validates_presence_of :name
  validates_presence_of :kind
end
```

每个部门有多个员工，同时部门名称和部门类型非空。这里由于部门号是主键，所以名称就不需要验证无重复了。

#### 3.1.3 员工

由于员工和客户有多个共同的属性，因此建立一个基类用于继承：

```ruby
class Person < ApplicationRecord
  self.abstract_class = true

  validates_uniqueness_of :person_id
  #validate :valid_person_id?
  validates_presence_of :name
  validates_presence_of :phone
  validates_presence_of :address

  def valid_person_id?
    errors.add :person_id, 'Invalid personal ID' unless person_id =~ %r![0-9]{17}[0-9xX]!
  end
end
```

这里为 Person 验证身份证号的唯一性，以及姓名电话地址非空。考虑到身份证号的合法性在本实验中并不重要，为了方便测试，就不验证身份证号的内容了（`validate :valid_person_id?` 即是按照中国身份证号的格式进行简单验证的操作）。

```ruby
class Staff < Person
  belongs_to :branch
  belongs_to :department

  has_many :clients, foreign_key: :manager_id, dependent: :restrict_with_error
end
```

每个员工属于一个支行和一个部门（即数据库里有 `branch_id` 和 `department_id` 列），同时有多个客户。但是由于客户表里关联员工的列名并不是 `staff_id`，需要使用 `foreign_key` 参数指定。

#### 3.1.4 客户

```ruby
class Client < Person
  belongs_to :manager, class_name: :Staff
  has_one :contact, dependent: :destroy
  has_many :ownerships, dependent: :restrict_with_error
  has_and_belongs_to_many :accounts, through: :ownerships
  has_and_belongs_to_many :loans, dependent: :restrict_with_error

  accepts_nested_attributes_for :contact, update_only: true, allow_destroy: true
end
```

每个客户属于一个负责人，这里 `belongs_to :manager` 指定数据库的列名为 `manager_id`，通过 `class_name` 指定实际关系类型为 Staff 而不是 Manager。同时每个客户有一个联系人，`dependent: :destroy` 指定删除客户时将联系人一并删除。`has_and_belongs_to_many :accounts, through: :ownerships` 表示客户并不直接与账户关联（没有 `account_id` 外键列），而是通过 Ownership 作为“中间类”与账户有多对多的关联，即客户账户关系需要经过 `ownerships` 进行一次额外的 JOIN。`accepts_nested_attributes_for :contact` 表示从网页提交的表单中接受联系人信息，这是因为默认情况下出于安全起见不允许通过表单直接修改关联实体。

#### 3.1.5 联系人

```ruby
class Contact < ApplicationRecord
  belongs_to :client

  validates_presence_of :name
  validates_presence_of :phone
  validates_presence_of :email
  validates_presence_of :relationship
end
```

联系人这里没有太多需要解释的，验证所有属性非空即可。

#### 3.1.6 账户

```ruby
class Account < ApplicationRecord
  belongs_to :branch
  belongs_to :accountable, polymorphic: true
  has_many :ownerships, dependent: :destroy
  #has_and_belongs_to_many :clients, through: :ownerships

  accepts_nested_attributes_for :accountable, :ownerships, update_only: true

  validate :check_balance
  validate :validate_owners

  # Credits: https://stackoverflow.com/a/32915379/5958455
  def build_accountable(params)
    self.accountable = accountable_type.safe_constantize.new params
  end

  def validate_owners
    errors.add :base, '关联客户至少有一位' if ownerships.empty?
  end

  def check_balance
    case accountable_type
    when 'DepositAccount'
      errors.add :base, '储蓄账户不允许欠款' if balance < 0.0
    when 'CheckAccount'
      errors.add :base, '支票账户欠款不允许超过透支额' if balance + accountable.withdraw_amount < 0.0
    end
  end
end
```

账户这里主要是多态关联的具体账户类型，`belongs_to :accountable, polymorphic: true` 表示数据库中有一列 `accountable_type` 指示实际的关联类型。其次就是验证账户必须要有至少一位客户作为所有者，同时对账户余额进行一些符合逻辑的验证。

#### 3.1.7 账户类型

由于储蓄账户和支票账户都是“具体账户类型”，因此使用一个 Active Record Concern 将公共元素提取出来：

```ruby
module Accountable
  extend ActiveSupport::Concern

  included do
    has_one :account, as: :accountable, dependent: :destroy

    accepts_nested_attributes_for :account

    validates_presence_of :account
  end
end
```

接下来就可以使用这个公共元素作为 mixin 了：

```ruby
class DepositAccount < ApplicationRecord
  include Accountable

  validates_numericality_of :interest_rate, greater_than_or_equal_to: 0.0
end
```

```ruby
class CheckAccount < ApplicationRecord
  include Accountable
end
```

这里没有太多需要解释的，显然储蓄账户的利率不能为负。

#### 3.1.8 客户账户关系

```ruby
class Ownership < ApplicationRecord
  belongs_to :branch
  belongs_to :client
  belongs_to :account

  validates_uniqueness_of :client, scope: %i[branch accountable_type]

  before_save :update_access_time
  before_destroy :check_owners_count

  def update_access_time
    self.last_access = Time.now
  end

  def check_owners_count
    return if account.ownerships.count > 1
    errors.add :base, '关联客户至少有一位'
    throw :abort
  end
end
```

每个关系属于一个客户和一个账户，如 2.3.7 节所述，额外加入了账户所属支行和账户类型用于进行唯一性约束。同时使用 Active Record 的 `before_save` 钩子在每次修改时更新「客户最近访问账户时间」，并使用 `before_destroy` 在删除前确保至少有两位客户（不能删掉一个账户的最后一位关联客户）。

#### 3.1.9 贷款

```ruby
class Loan < ApplicationRecord
  belongs_to :branch
  has_and_belongs_to_many :clients
  has_many :issues, dependent: :destroy

  validates_presence_of :clients
  validates_numericality_of :amount, greater_than: 0.0

  before_destroy :check_issuing

  def check_issuing
    if status == :issuing
      errors.add :base, '发放中的贷款不允许删除'
      throw :abort
    end
  end

  def status
    if issues.empty?
      :unissued
    elsif issues.sum(:amount) == amount
      :issued
    else
      :issuing
    end
  end

  def remaining
    @remaining ||= amount - issues.sum(:amount)
  end

  def reset_remaining
    @remaining = nil
  end
end
```

贷款这里多了几个函数，主要是提供了支付状态属性（从数据库计算）以及利用该支付状态属性在删除前进行验证。同时对贷款的验证主要就一个大于零，因为数额为零的贷款没有意义。

#### 3.1.10 贷款支付

```ruby
class Issue < ApplicationRecord
  belongs_to :loan

  validates_numericality_of :amount, greater_than: 0.0
  validate :check_amount, on: :create

  def check_amount
    if amount > loan.remaining
      errors.add :base, '支付不能超出贷款总额'
    else
      loan.reset_remaining
    end
  end
end
```

贷款支付的主要内容就是验证，一个是大于零（同样，一笔零元的支付是没有意义的），一个是支付后不能超出贷款总额。

### 3.2 Action Controller 控制器

#### 3.2.1 默认动作 / 共同动作

`rails generate scaffold_controller` 会生成很多默认代码 / 模板代码，其中不少都直接采用了，没有进行额外的加工，因此这些动作在六大类模型（支行、部门、员工、客户、账户、贷款）中基本一致，所以放在开头一个单独的小节统一介绍，以下小节只介绍对应控制器与默认的不同之处。

Rails 自动生成的控制器包含了 7 个动作：

- `index`：列出对应模型的全部对象
- `show`：根据 `id` 为一个对象显示详情
- `new`：显示“新建对象”页面，渲染网页表单（Form）
- `edit`：显示“编辑对象”页面，渲染网页表单
- `create`：实际创建对象的动作，采用 HTTP POST 方式，一般通过点击「新建」页面的【提交】按钮触发
- `update`：实际修改对象的动作，采用 HTTP PATCH 方式，一般通过点击「编辑」页面的【提交】按钮触发
- `destroy`：删除对象的动作，采用 HTTP DELETE 方式，一般通过点击「删除」按钮触发

其中部分动作包含一些默认代码（如 index 中的 `@objects = Object.all`）以使其立即可用。

另外还包括两个助手方法（helper methods）：

- `set_object`：对于 show, edit, update, destroy 这四个动作，查询数据库获得当前正在操作对象以便使用数据。使用 `before_action` 钩子自动调用
- `object_params`：过滤传入的参数，指定必须存在的参数（如要创建 / 修改的对象）及可接受的参数

下面以部门控制器 `DepartmentsController` 的代码为例，展示这部分“默认动作”：

```ruby
class DepartmentsController < ApplicationController
  before_action :set_department, only: %i[show edit update destroy]

  # GET /departments
  def index
    @departments = Department.order(:id)
  end

  # GET /departments/1
  def show
  end

  # GET /departments/new
  def new
    @department = Department.new
  end

  # GET /departments/1/edit
  def edit
  end

  # POST /departments
  def create
    @department = Department.new(department_params)

    if @department.save
      redirect_to @department, success: '成功创建部门'
    else
      render :new
    end
  end

  # PATCH/PUT /departments/1
  def update
    if @department.update(department_params)
      redirect_to @department, success: '成功更新部门'
    else
      render :edit
    end
  end

  # DELETE /departments/1
  def destroy
    if @department.destroy
      redirect_to departments_url, success: '部门已删除'
    else
      redirect_back fallback_location: departments_url, alert: '部门删除失败'
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_department
      @department = Department.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def department_params
      params.require(:department).permit(%i[name kind])
    end
end
```

#### 3.2.2 路由

服务器需要知道客户端（浏览器）访问的 URL 应该分派到哪个控制器的哪个动作上，以及如何解析 URL 中的参数（如数字 ID 等）。该部分路由配置位于 `config/routes.rb`。

由于这部分没有自己实现的特别逻辑等，因此 Rails 的官方文档完全可以胜任本节的解释工作，故不在此重复，仅附上链接：<https://guides.rubyonrails.org/routing.html>

#### 3.2.3 支行控制器

支行控制器 `BranchesController` 实现了 `staffs`，`accounts` 和 `loans` 三个额外的动作，分别路由至

```text
GET /branches/:id/accounts
GET /branches/:id/staffs
GET /branches/:id/loans
```

用于列出与支行关联的员工、账户和贷款，相关代码如下：

```ruby
class BranchesController < ApplicationController
  before_action :set_branch, only: %i[show accounts loans staffs edit update destroy]
  before_action :set_staffs, only: %i[show staffs]
  before_action :set_accounts, only: %i[show accounts]
  before_action :set_loans, only: %i[show loans]

  private
    def set_branch
      @branch = Branch.find(params[:id])
    end

    def set_staffs
      @staffs = Staff.where(branch: @branch)
    end

    def set_accounts
      @accounts = Account.where(branch: @branch)
    end

    def set_loans
      @loans = Loan.where(branch: @branch)
    end
end
```

对应的，Action View 会自动渲染 `branches/accounts.html.erb` 等模板，相关内容在 3.3 节详细介绍。

#### 3.2.4 部门控制器

部门控制器实现了 `staffs` 一个额外的动作，路由至 `GET /departments/:id/staffs`，用于列出部门下属的员工，相关代码如下：

```ruby
class DepartmentsController < ApplicationController
  before_action :set_department, only: %i[show staffs edit update destroy]
  before_action :set_staffs, only: %i[show staffs]

  private
    def set_department
      @department = Department.find(params[:id])
    end

    def set_staffs
      @staffs = Staff.where(department: @department)
    end
end
```

#### 3.2.5 员工控制器

员工控制器实现了 `clients` 一个额外的工作，路由至 `GET /staffs/:id/clients`，用于列出该员工负责的客户。另外，为了显示员工所属的支行和部门，查询时默认连结了支行和部门的表，并从两个表中选取名称列。相关代码如下：

```ruby
class StaffsController < ApplicationController
  before_action :set_staff, only: %i[show clients edit update destroy]
  before_action :set_clients, only: %i[show clients]

  private
    def staffs
      @staffs ||= Staff.joins(:branch, :department).select('staffs.*', 'branches.name AS branch_name', 'departments.name AS department_name')
    end

    def set_clients
      @clients = Client.joins(:manager).where(manager: @staff)
    end
end
```

#### 3.2.6 客户控制器

客户控制器实现了 `accounts` 和 `loans` 两个额外的动作，分别路由至

```text
GET /clients/:id/accounts
GET /clients/:id/loans
```

用于列出与客户关联的账户及贷款，相关代码如下：

```ruby
class ClientsController < ApplicationController
  include AccountsHelper

  before_action :set_client, only: %i[edit update destroy accounts loans]

  # GET /clients/1/accounts
  def accounts
    @accounts = Ownership.joins(:account, :branch).where(client: @client).select('ownerships.*', 'accounts.balance AS balance', 'branches.name AS branch_name')
  end

  # GET /clients/1/loans
  def loans
    @loans = Loan.joins(:clients, :branch).where('clients.id = ?', @client.id).select('loans.*', 'branches.name AS branch_name')
  end
end
```

同时，由于联系人作为一个单独的实体（表）存储，在新建客户时，为了能够正确生成联系人相关表格，对 `new` 动作进行了一些修改，相关代码如下：

```ruby
# GET /clients/new
def new
  @client = Client.new
  @client.build_contact
end
```

#### 3.2.7 账户控制器

账户控制器实现了 `owners` 一个额外的动作，路由至 `GET /accounts/:id/owners`，用于显示与账户关联的所有者，相关代码如下：

```ruby
class AccountsController < ApplicationController
  before_action :set_account, only: %i[show edit owners update destroy]

  # GET /accounts/1/owners
  def owners
    @ownership = Ownership.new
    @owners = @account.ownerships.joins(:client).select('ownerships.*', 'clients.name AS client_name')
    @available_clients = Client.where.not(id: Ownership.where(branch_id: @account.branch_id, accountable_type: @account.accountable_type).select(:client_id)).select(:id, :name)
  end
end
```

其中该页面包含了新增账户关联客户的表格，因此加入了 `@ownership = Ownership.new` 以使表格能够正常渲染，同时构造 `@available_clients` 列表用于填充表格中的下拉菜单，自动过滤掉不符合要求的客户（即不能够添加为当前账户所有者的客户）。

由于账户的创建涉及对应多态关联的维护，因此修改了 `create` 方法，增加相关维护逻辑，代码如下：

```ruby
# POST /accounts
def create
  params = account_params
  accountable_type = params[:accountable_type]
  @typed_account = accountable_type.safe_constantize.new(params[:accountable_attributes])
  # Insert account and branch info into ownership
  params[:ownerships_attributes]&.each_value do |attr|
    attr.merge!(accountable_type: accountable_type, branch_id: params[:branch_id])
  end
  @account = @typed_account.build_account(params)

  if @account.save
    redirect_to @account, success: '成功创建账户'
  else
    render :new
  end
end
```

由于账户更改支行涉及额外的验证及处理，`update` 方法需要完全重写，添加对修改支行情况的处理，代码如下：

```ruby
# PATCH/PUT /accounts/1
def update
  if update_params[:branch_id].to_i != @account.branch_id
    client_ids = Ownership.where(account: @account).select(:client_id)
    target_client_ids = Ownership.where(branch_id: update_params[:branch_id], client_id: client_ids)
    unless target_client_ids.empty?
      target_client_ids.joins(:branch, :client).select('branches.name AS branch_name', 'clients.name AS client_name').each do |target|
        errors << "客户 #{target.client_name} 在支行 #{target.branch_name} 已有账户"
      end
      render :edit and return
    end

    Account.transaction do
      Ownership.where(account: @account).update_all(branch_id: update_params[:branch_id])
      @account.update! update_params
    end
  else
    @account.update! update_params
  end
  redirect_to @account, success: '成功更新账户'
rescue ActiveRecord::ActiveRecordError
  render :edit, alert: '账户更新失败'
end
```

首先使用 if 判断客户端提交上来的表格中支行是否被修改（与记录值不一致），若未修改则不需要验证。验证过程首先构建查询找出当前账户的全部关联客户，然后通过 `WHERE id IN (subquery)` 的方式判断这些客户中是否已有人在目标支行拥有相同类型的账户，若有则将这些客户列出作为错误信息返回。此时初步验证通过，需要同时更新「账户所有者」表中与该账户关联记录的「支行」列，再使用其他表格数据更新账户的其他属性。由于此处两步更新可能出错（如账户余额不符合要求等），故将两个更新操作包装在一个事务中，即 `Account.transaction` 代码块。

#### 3.2.8 客户账户关系控制器

由于客户账户关系不是独立的实体，因此该控制器不符合 3.2.1 节的介绍。

该控制器仅包含 `create` 和 `destroy` 两个动作，分别用于增减账户的关联客户，路由至

```text
POST /accounts/:id/owners
DELETE /accounts/:id/owners
```

除此之外，其实现逻辑与普通实体的创建与删除无异。个别细节如下所示：

```ruby
# POST /accounts/1/owners
def create
  owner = Ownership.new ownership_params

  if owner.save
    redirect_to account_owners_url(@account), success: '成功为账户添加客户'
  else
    render 'accounts/owners'
  end
end
```

由于客户账户关系没有独立的页面，因此在创建成功后回到账户页面，在创建失败时重新渲染相同页面，因此使用 `render 'accounts/owners'` 指定模板，避免 Action View 根据默认规则寻找 `ownerships/create` 页面。

#### 3.2.9 贷款控制器

贷款控制器实现了 `issues` 一个额外的动作，路由至 `GET /loans/:id/issues`，用于显示贷款的发放记录，相关代码如下：

```ruby
class LoansController < ApplicationController
  before_action :set_loan, only: %i[show issues clients add_client destroy_client destroy]
  before_action :set_issues, only: %i[issues]
    
  # GET /loans/1/issues
  def issues
    @issue = Issue.new
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_loan
      id = params[:id]
      @loan = Loan.left_outer_joins(:branch, :issues).group(:id).select('loans.*', 'branches.name AS branch_name', 'IFNULL(SUM(issues.amount), 0.0) AS amount_issued', 'loans.amount - IFNULL(SUM(issues.amount), 0.0) AS remaining').find(id)
      @clients = Loan.left_outer_joins(:clients).where('loans.id = ?', id)
      @status = status_of @loan
    end

    def set_issues
      @issues = @loan.issues.order(date: :asc, id: :asc)
    end
end
```

其中获取贷款数据通过 LEFT OUTER JOIN 的方式连结贷款发放表，获取支付金额的同时避免没有支付记录的贷款被过滤掉。

另外，由于贷款不能修改，因此贷款控制器从默认动作中删掉了 `create` 和 `update`。

#### 3.2.10 贷款发放控制器

由于贷款不是独立的实体，因此该控制器不符合 3.2.1 节的介绍。

该控制器仅包含 `create` 一个动作，用于为贷款添加一笔新的支付记录，路由至 `POST /loans/:id/issues`。除此之外，其实现逻辑与普通实体的创建无异。相关代码如下：

```ruby
# POST /loans/1/issues
def create
  @issue = Issue.new issue_params

  if @issue.save
    redirect_to loan_issues_url(@loan), success: '成功添加支付'
  else
    redirect_to loan_issues_url(@loan), alert: @issue.errors.full_messages.first
  end
end
```

其中金额验证等在 Active Record 模型处理，详细内容见 3.1.10 节。

#### 3.2.11 统计信息控制器

由于业务统计没有对应的实体，因此该控制器不符合 3.2.1 节的介绍。

该控制器实现了业务统计相关的 `home`, `index`, `deposit`, `loan` 四个动作，分别为

- `home` 负责显示应用程序主页，路由至 `GET /`
- `index` 负责显示业务统计页面，路由至 `GET /stats`
- `deposit` 负责提供储蓄业务的查询功能，路由至 `GET /stats/deposit`
- `loan` 负责提供贷款业务的查询功能，路由至 `GET /stats/loan`

其中`home` 为主页动作，只需准备需要在主页上显示的各大类模型，代码如下：

```ruby
class StatsController < ApplicationController
  # GET /
  def home
    @cards = [Branch, Department, Staff, Client, Account, Loan].zip \
      %w[safe department manager user credit-card debt]
  end
end
```

`index` 为「业务统计」页面，此处需要处理在页面上显示的「概览」数据，其代码如下：

```ruby
class StatsController < ApplicationController
  # GET /stats
  def index
    @branches_count = Branch.count
    @accounts_count, @accounts_amount = Account.pluck('COUNT(id)', 'SUM(balance)').first
    Account.group(:accountable_type).pluck('COUNT(id)', :accountable_type).each do |count, type|
      @deposit_accounts_count = count if type == 'DepositAccount'
      @check_accounts_count = count if type == 'CheckAccount'
    end
    @loans_count, @loans_amount = Loan.pluck('COUNT(id)', 'SUM(amount)').first
    loan_statuses = Loan.left_outer_joins(:issues).group(:id).select(:id, %[
      CASE
        WHEN IFNULL(SUM(issues.amount), 0) = 0 THEN 0
        WHEN SUM(issues.amount) = loans.amount THEN 2
        ELSE 1
      END AS status
    ].squish)
    Loan.from(loan_statuses, :statuses).group(:status).select('COUNT(id) AS count', :status).each do |row|
      case row.status
      when 0
        @unissued = row.count
      when 2
        @issued = row.count
      else
        @issuing = row.count
      end
    end
    @issues_amount = Issue.sum(:amount)

    @deposit_card_content = %w[支行 账户 总金额 储蓄账户 支票账户].zip [
      @branches_count, @accounts_count, helpers.currency_value(@accounts_amount),
      (@deposit_accounts_count ||= 0), (@check_accounts_count ||= 0),
    ]
    @loan_card_content = %w[支行 贷款 总金额 已支付 未发放 发放中 已发放].zip [
      @branches_count, @loans_count,
      helpers.currency_value(@loans_amount), helpers.currency_value(@issues_amount),
      (@unissued ||= 0), (@issuing ||= 0), (@issued ||= 0),
    ]
  end
end
```

该部分代码为页面准备了以下数据：

- 储蓄业务
  - 支行数
  - 账户数
  - 账户余额总数
  - 储蓄账户数
  - 支票账户数
- 贷款业务
  - 支行数
  - 贷款笔数
  - 贷款总金额
  - 已支付的总金额
  - 未开始发放的贷款数
  - 发放中的贷款数
  - 已发放完毕的贷款数

 `deposit` 和 `loan` 页面都包含一个搜索表格，通过 URL parameters 传入搜索参数，准备及处理搜索参数的相关代码如下：

```ruby
class StatsController < ApplicationController
  before_action :set_form, only: %i[deposit loan]

  private

  def search_params
    @url_params ||= request.GET
  end

  def set_form
    @action = search_params[:action]
    @branches = (search_params[:branch] || '').split(' ').map(&:to_i)
    @start_date = Date.parse search_params[:start_date] rescue Date.today.at_beginning_of_month
    @end_date = Date.parse search_params[:end_date] rescue Date.today
    @end_year = Date.today.year
    valid_time_spans = %i[none month quarter year]
    @time_spans = %w[无 月 季度 年].zip valid_time_spans
    @time_span = (search_params[:time_span] || :none).to_sym
    @time_span = :none unless valid_time_spans.include? @time_span
  end
end
```

其中 `search_params` 函数从请求的 URL 解析搜索参数，`set_form` 函数从搜索参数中解析选项和数值等具体参数，以及处理默认选项等。

下面为 `deposit` 和 `loan` 动作的代码，它们基本一致：

```ruby
class StatsController < ApplicationController
  # GET /stats/deposit
  def deposit
    @start_year = Account.order(open_date: :asc).select(:open_date).first&.open_date&.year || Date.today.year
    return unless @action

    wheres = {}
    selects = ['accounts.*',
               'COUNT(DISTINCT ownerships.client_id) AS clients_count',
               'SUM(balance) AS total_amount',
               'branches.name AS branch_name']
    groups = ['accounts.branch_id']
    orders = {}

    wheres[:branch_id] = @branches unless @branches.empty?

    # Apparently this is MySQL-specific
    case @time_span
    when :year
      selects << 'YEAR(open_date) AS open_year'
      selects << 'YEAR(open_date) AS display_time'
      groups << 'open_year'
      orders = { open_year: :asc, branch_id: :asc }
    when :quarter
      selects << 'YEAR(open_date) AS open_year'
      selects << '((MONTH(open_date) + 2) DIV 3) AS open_quarter'
      selects << 'CONCAT(YEAR(open_date), " Q", (MONTH(open_date) + 2) DIV 3) AS display_time'
      groups << 'open_quarter'
      orders = { open_year: :asc, open_quarter: :asc, branch_id: :asc }
    when :month
      selects << 'YEAR(open_date) AS open_year'
      selects << 'MONTH(open_date) AS open_month'
      selects << 'CONCAT(YEAR(open_date), "-", LPAD(MONTH(open_date), 2, "0")) AS display_time'
      groups << 'open_month'
      orders = { open_year: :asc, open_month: :asc, branch_id: :asc }
    else
      selects << 'open_date'
      selects << 'open_date AS display_time'
      groups << 'open_date'
      orders = { open_date: :asc, branch_id: :asc }
    end

    @query = Account.select(selects).joins(:branch).where(wheres).group(groups).order(orders)
    @data_branches = @query.except(:select, :group, :order).select('DISTINCT branch_id', 'branches.name AS branch_name').order(branch_id: :ASC)
    @query = @query.joins(:ownerships)
    @record_groups = @query.group_by(&:branch_id).sort_by { |k, v| k }
  end

  # GET /stats/loan
  def loan
    @start_year = Issue.order(date: :asc).select(:date).first&.date&.year || Date.today.year
    return unless @action

    wheres = {}
    selects = ['loans.*', 'issues.date AS date',
               '@clients_count := COUNT(DISTINCT clients.id) AS clients_count',
               'SUM(issues.amount / @clients_count) AS total_amount',
               'branches.name AS branch_name']
    groups = ['loans.branch_id', 'loans.id']
    orders = {}

    wheres[:branch_id] = @branches unless @branches.empty?

    case @time_span
    when :year
      selects << 'YEAR(date) AS year'
      selects << 'YEAR(date) AS display_time'
      groups << 'year'
      orders = { year: :asc, branch_id: :asc }
    when :quarter
      selects << 'YEAR(date) AS year'
      selects << '((MONTH(date) + 2) DIV 3) AS quarter'
      selects << 'CONCAT(YEAR(date), " Q", (MONTH(date) + 2) DIV 3) AS display_time'
      groups << 'quarter'
      orders = { year: :asc, quarter: :asc, branch_id: :asc }
    when :month
      selects << 'YEAR(date) AS year'
      selects << 'MONTH(date) AS month'
      selects << 'CONCAT(YEAR(date), "-", LPAD(MONTH(date), 2, "0")) AS display_time'
      groups << 'month'
      orders = { year: :asc, month: :asc, branch_id: :asc }
    else
      selects << 'date'
      selects << 'date AS display_time'
      groups << 'date'
      orders = { date: :asc, branch_id: :asc }
    end

    @query = Loan.select(selects).joins(:branch).where(wheres).group(groups).order(orders)
    @data_branches = @query.except(:select, :group, :order).select('DISTINCT branch_id', 'branches.name AS branch_name').order(branch_id: :ASC)
    @query = @query.joins(:clients, :issues)
    @record_groups = @query.group_by(&:branch_id).sort_by { |k, v| k }
  end
end
```

首先若没有查询动作（action 为空），则直接返回页面，此时的页面没有「搜索结果」部分，仅包含搜索表格。若有查询动作，则根据搜索参数构建 SQL 语句，其中主要内容是区分按月、按季度和按年归纳的部分。构建好查询之后将结果按支行归类以便显示。

### 3.3 Action View 视图

由于 Rails 会自动根据控制器和动作构建路径寻找 Action View 模板（见 <https://guides.rubyonrails.org/layouts_and_rendering.html>），因此项目的 `/app/views` 目录仅包含 HTML 模板，不包含搜索模板及传递数据等相关代码，故本节也仅介绍所用 HTML 模板及其他前端相关设计。

由于各个模型的列表页面、详细信息页面及编辑页面具有相同的结构，因此不分别介绍，这部分内容在 3.3.3 节至 3.3.6 节统一介绍。

为避免重复，本章节不包含实际效果展示，所有截图都在第 4 章展示。

#### 3.3.1 主布局 `layouts/application`

`layouts/application.html.erb` 为整个应用程序的基本模板，定义了 HTML 框架及在其他页面中可指定的部分（`content_for`）。所有其他页面都从该模板继承。

下面为 HTML `<head>` 部分定义：

```erb
<head>
  <title>
    <%= if content_for?(:title) then yield(:title) + ' - ' end %>
    <%= site_name %>
  </title>
  <%= favicon_link_tag asset_path('bank.png'), type: 'image/png' %>
  <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1">
  <%= csrf_meta_tags %>
  <%= csp_meta_tag %>

  <%= stylesheet_link_tag "https://cdn.jsdelivr.net/npm/bootstrap@4.5.0/dist/css/bootstrap.min.css", integrity: "sha256-aAr2Zpq8MZ+YA/D6JtRD3xtrwpEz2IqOS+pWD/7XKIw=", crossorigin: :anonymous %>
  <%= stylesheet_link_tag "https://cdn.jsdelivr.net/npm/@fortawesome/fontawesome-free@5/css/all.min.css", crossorigin: :anonymous %>
  <%= stylesheet_link_tag 'application', media: :all %>
  <%= yield :head %>
</head>
```

该部分内容作用如下：

- 定义页面标题格式为 *页面名称 - 网站名称*
- 显示网站图标（即 favicon）
- 生成 [CSRF](https://en.wikipedia.org/wiki/Cross-site_request_forgery) 与 [CSP](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy) 标签
- 从 [jsDelivr CDN](https://www.jsdelivr.com/) 载入 [Boostrap 4](https://getbootstrap.com/docs/4.5/getting-started/introduction/) 样式表以及 [Font Awesome 5](https://fontawesome.com/) 图标样式表
- 载入一些自定义的样式表，详细信息在 3.4 节介绍
- 为额外的头部信息提供插入位置，该功能在其他模板中并没有用到

下面为 HTML `<body>` 部分定义（精简内容）：

```erb
<body class="d-flex flex-column min-vh-100">
  <nav class="navbar navbar-expand-md navbar-light shadow-sm">
  </nav>

  <div class="initial-content flex-grow-1 my-3 my-md-4 container px-sm-0">
    <% unless alert.nil? %>
      <div id="alert" class="alert alert-danger"><%= alert %></div>
    <% end %>
    <% unless success.nil? %>
      <div id="success" class="alert alert-success"><%= success %></div>
    <% end %>
    <% unless notice.nil? %>
      <div id="notice" class="alert alert-primary"><%= notice %></div>
    <% end %>

    <%= yield %>
  </div>

  <footer class="footer shadow py-3 py-md-4 border-top">
  </footer>

  <%# Optional scripts %>
</body>
```

该部分定义了网页页面实际显示的内容，主要包含四部分：

- 顶部导航栏
- 主体内容
- 页脚
- 额外的脚本，放置在页面底部以保证在页面加载完成后才加载

其中为了使页脚在页面内容较少时也能正确保持在页面底部，采用了 CSS Flex 的方案，因此 `body` 元素上有 `d-flex flex-column min-vh-100` 等类，主体内容的外部 `div` 容器上有 `flex-grow-1` 等类。详情见 Stack Overflow 上的[这篇回答](https://stackoverflow.com/a/34146411/5958455)。

下面为导航栏的代码：

```erb
<nav class="navbar navbar-expand-md navbar-light shadow-sm">
  <%= link_to root_path, class: 'navbar-brand' do %>
    <%= image_tag "bank.svg", data: { svg_fallback: asset_path('bank.svg') }, class: 'svg-inline' %>
    <%# site_name %>
    iBug 银行
  <% end %>
  <button class="navbar-toggler" type="button" data-toggle="collapse" data-target="#navbar-content" aria-controls="navbar-content" aria-expanded="false" aria-label="Toggle navigation">
    <span class="navbar-toggler-icon"></span>
  </button>
  <div class="collapse navbar-collapse" id="navbar-content">
    <ul class="navbar-nav mr-auto">
      <% navbar_models.each do |model, icon| %>
        <li class="nav-item <%= active_page url_for model %>">
          <%= link_to url_for(model), class: 'nav-link' do %>
            <i class="fas fa-fw fa-<%= icon %>"></i>
            <%= model.model_name.human %>
          <% end %>
        </li>
      <% end %>

      <li class="nav-item dropdown">
        <a class="nav-link dropdown-toggle" data-toggle="dropdown" href="#" role="button" aria-haspopup="true" aria-expanded="false">
          <i class="fas fa-fw fa-chart-pie"></i>
          统计
        </a>
        <div class="dropdown-menu">
          <% navbar_stats.each do |path, icon, name| %>
            <%= link_to path, class: "dropdown-item #{active_page path}" do %>
              <i class="fas fa-fw fa-<%= icon %>"></i>
              <%= name %>
            <% end %>
          <% end %>
        </div>
      </li>
    </ul>
    <ul class="navbar-nav my-2 my-md-0">
      <li class="nav-item">
        <%= link_to about_path, class: 'nav-link d-lg-block' do %>
          <i class="fas fa-fw fa-info-circle"></i>
          关于
        <% end %>
      </li>
    </ul>
  </div>
</nav>
```

导航栏内容从左往右为

- 网站标题，链接至主页
- 各个模型（Active Record models）的列表页面
- 【统计】，是一个下拉菜单，其中包含三个选项：
  - 【业务统计】，即该类的主页（见 3.2.11 节）
  - 储蓄业务的搜索页面
  - 贷款业务的搜索页面
- 导航栏右侧为一个「关于」页面，包含一些介绍性文字

其中 `active_page` 为自己编写的一个帮助函数，用于对匹配的当前页面生成 active 文字，用作 CSS class 高亮显示，其内容为：

```ruby
module ApplicationHelper
  def active_page(page)
    current_page?(page) ? 'active' : ''
  end
end
```

下面为页脚的代码：

```erb
<footer class="footer shadow py-3 py-md-4 border-top">
  <div class="container px-sm-0">
    <p class="text-muted my-0">
    <a href="https://github.com/iBug/Junk-Bank-System">Junk Bank System</a>, Copyright &copy; 2020-<%= Time.now.strftime '%Y' %> <a href="https://github.com/iBug">iBug</a>
    <br />
    Revision <a href="https://github.com/iBug/Junk-Bank-System/commit/<%= git_revision %>"><code><%= git_revision_short %></code></a>
    </p>
  </div>
</footer>
```

该页脚仅包含几个链接和版本信息，是出于美观的考虑而设置的。其中 `git_revision` 和 `git_revision_short` 为两个自定义的帮助函数，从 Rails configurations 中获取当前目录的 Git 版本信息。

下面为页面底部脚本的代码：

```erb
<%# Optional scripts %>
<%# jQuery, Popper.js, Bootstrap, Rails UJS, Font Awesome, Vue.js %>
<%= javascript_include_tag "https://cdn.jsdelivr.net/npm/vue@2.6.11/dist/vue.min.js", integrity: "sha256-ngFW3UnAN0Tnm76mDuu7uUtYEcG3G5H1+zioJw3t+68=", crossorigin: "anonymous" %>
<%= javascript_include_tag "https://cdn.jsdelivr.net/npm/jquery@3.5.1/dist/jquery.min.js", integrity: "sha256-9/aliU8dGd2tb6OSsuzixeV4y/faTqgFtohetphbbj0=", crossorigin: "anonymous" %>
<%= javascript_include_tag "https://cdn.jsdelivr.net/npm/bootstrap@4.5.0/dist/js/bootstrap.bundle.min.js", integrity: "sha256-Xt8pc4G0CdcRvI0nZ2lRpZ4VHng0EoUDMlGcBSQ9HiQ=", crossorigin: "anonymous", async: true %>
<%= javascript_include_tag "https://cdn.jsdelivr.net/npm/rails-ujs/lib/assets/compiled/rails-ujs.min.js", crossorigin: "anonymous", async: true %>
<%= yield :body_after %>
```

该部分代码按顺序载入 Vue.js，jQuery，Bootstrap 的脚本以及 [Rails UJS](https://github.com/rails/rails/tree/master/actionview/app/assets/javascripts) 帮助脚本，并提供了一个在脚本加载完毕后插入内容的位置。

#### 3.3.2 首页

#### 3.3.3 卡片布局

本布局使用 [Bootstrap 的卡片外观](https://getbootstrap.com/docs/4.5/components/card/)实现，代码如下：

```erb
<div class="card border-info">
  <div class="card-header shadow-sm bg-info text-white text-center">
    <%= yield :heading %>
  </div>

  <div class="card-body">
    <%= yield :body %>
  </div>

  <div class="card-footer bg-info text-white text-center">
    <%= yield :footer %>
  </div>
</div>

<%= yield :after %>
```

#### 3.3.4 列表页面

列表页面基于 3.3.3 节所述的卡片布局，卡片标题为页面标题，卡片主体为一个表格（即 `<table>`），列出该模型的所有对象。下面以支行列表页面 `branches/index.html.erb` 为例展示：

```erb
<% content_for :heading do %>
  <h1 class="mb-0"><%= title '支行' %></h1>
<% end %>

<% content_for :body do %>
  <table class="table table-hover mb-0 with-action">
    <thead>
      <tr>
        <th>支行名称</th>
        <th>城市</th>
        <th>资产</th>
        <th>操作</th>
      </tr>
    </thead>

    <tbody id="search-content">
      <% @branches.each do |branch| %>
        <tr>
          <td><%= link_to branch.name, branch %></td>
          <td><%= branch.city %></td>
          <td><%= branch.assets %></td>
          <td>
            <%= link_to raw(t'actions.view'), branch, class: 'btn btn-outline-primary' %>
            <%= link_to raw(t'actions.edit'), edit_branch_path(branch), class: 'btn btn-outline-secondary' %>
            <%= link_to raw(t'actions.destroy'), branch, method: :delete, class: 'btn btn-outline-danger', data: { confirm: t('confirm') } %>
          </td>
        </tr>
      <% end %>
    </tbody>
  </table>
<% end %>

<% content_for :footer do %>
  <div>
    <%= link_to '新建支行', new_branch_path, class: 'btn btn-success' %>
    <a class="btn btn-primary" href="#search-form" data-toggle="collapse" role="button" aria-expanded="false" aria-controls="search-form"><%= raw(t'actions.search') %></a>
  </div>
  <%= render partial: 'quick_search' %>
<% end %>

<%= render template: 'layouts/listing' %>
```

卡片标题与页面标题一致，使用自定义的 `title` 帮助函数完成，其代码如下：

```ruby
module ApplicationHelper
  def title(text)
    content_for :title, text
    text
  end
end
```

卡片主体只有一个表格，使用了一些 Bootstrap 样式及自定义样式（见 3.4.2 节）以美化，

卡片脚部包含了一个指向「新建支行」页面，以及页面内的快捷搜索功能。

##### 快捷搜索功能

页面内的快捷搜索功能采用纯前端方案实现，具体做法为文字匹配，支持正则表达式。

搜索功能由两个部件组成，控制部件与内容部件，其中内容部件即上面代码中的 `<tbody id="search-content">`，控制部件由一个【搜索】按钮和展开式搜索输入框组成。点击【搜索】按钮会展开 / 隐藏输入框，该特性使用 Bootstrap 实现。搜索输入框为一个普通的文本输入框，其使用 `oninput` 事件在输入时执行 JavaScript 代码。`quick_search` 部件代码如下：

```erb
<div class="collapse" id="search-form">
  <div class="form-group pt-3 mb-0">
    <input id="search-input" type="text" class="form-control" placeholder="输入以开始搜索">
  </div>
</div>

<% content_for :after do %>
  <%= javascript_include_tag "quick-search.js", async: true, defer: true %>
<% end %>
```

搜索代码 `quick-search.js` 如下：

```javascript
document.getElementById('search-input').oninput = function() {
  var searchTerm = document.getElementById('search-input').value;
  var searchRegex = undefined;
  try {
    searchRegex = new RegExp(searchTerm);
  } catch {
    // Bad regex, ignore
  }
  var tbody = document.getElementById('search-content');

  for (let i = 0; i < tbody.children.length; i++) {
    var tr = tbody.children[i];
    var match = false;
    var texts = [];

    // Filter: Exclude last element because it contains only action buttons
    for (let j = 0; j < tr.children.length - 1; j++) {
      var td = tr.children[j];
      texts.push(td.innerText);
    }
    var text = texts.join("\n");

    if (text.indexOf(searchTerm) !== -1) {
      match = true;
    } else if (typeof searchRegex !== "undefined" && searchRegex.test(text)) {
      match = true;
    }
    tr.style.display = match ? "" : "none";
  }
};
```

该代码首先尝试将文本框内容作为正则表达式编译，若编译失败则忽略。随后对表格的每一行进行文字匹配与（若正则表达式编译成功）正则匹配，将不匹配的行全部隐藏。由于空字符串是任何字符串的子串，所以当输入框为空时所有内容都显示出来，符合直觉。

#### 3.3.5 详细信息页面

详细信息页面同样使用卡片布局，但与列表页面不同之处在于详细信息页面不使用 `<table>` 列出信息，而是使用 [`<dl>` 标签](https://developer.mozilla.org/en/docs/Web/HTML/Element/dl)。除此之外，由于详细信息页面一次只列出一个对象，所以其通常包含更多信息（如支行的关联员工、账户、贷款等），这在列表页面会带来大量的数据库查询，但在详细信息页面所使用的额外数据库查询数量完全可以接受。下面以支行详细信息页面 `branches/show.html.erb` 为例展示：

```erb
<% content_for :heading do %>
  <h1 class="mb-0"><%= title "支行 #{@branch.name}" %></h1>
<% end %>

<% content_for :body do %>
  <dl class="row my-0">
    <dt class="col col-12 col-md-2">名称</dt>
    <dd class="col col-12 col-md-10"><%= @branch.name %></dd>
    <dt class="col col-12 col-md-2">城市</dt>
    <dd class="col col-12 col-md-10"><%= @branch.city %></dd>
    <dt class="col col-12 col-md-2">资产</dt>
    <dd class="col col-12 col-md-10"><%= @branch.assets %></dd>
    <dt class="col col-12 col-md-2">员工</dt>
    <dd class="col col-12 col-md-10">
      <%= list_items @staffs, view_all: branch_staffs_path(@branch) %>
    </dd>
    <dt class="col col-12 col-md-2">账户</dt>
    <dd class="col col-12 col-md-10">
      <%= list_items @accounts, name_field: :id, separator: ',', view_all: branch_accounts_path(@branch) %>
    </dd>
    <dt class="col col-12 col-md-2">贷款</dt>
    <dd class="col col-12 col-md-10">
      <%= list_items @loans, name_field: :id, separator: ',', view_all: branch_loans_path(@branch) %>
    </dd>
  </dl>
<% end %>

<% content_for :footer do %>
  <%= link_to raw(t'actions.edit'), edit_branch_path(@branch), class: 'btn btn-primary' %>
  <%= link_to raw(t'actions.back'), branches_path, class: 'btn btn-secondary' %>
  <%= link_to raw(t'actions.destroy'), @branch, method: :delete, class: 'btn btn-danger', data: { confirm: t('confirm') } %>
<% end %>

<%= render template: 'layouts/card.html' %>
```

标题的实现方式与列表页面相同，除了内容增加了识别信息（对于支行、部门、员工和客户，使用名称作为识别信息，对于账户和贷款则使用编号）。

主体部分为一个 `<dl>` 元素，列出所展示对象的全部适用的属性及关联对象。`list_items` 为一个自定义帮助函数，其内容如下：

```ruby
module ApplicationHelper
  def list_items(items, options = {})
    render partial: 'inline_listing', locals: options.merge(items: items)
  end
end
```

对应的列表模板 `application/_inline_listing.html.erb` 如下：

```erb
<% limit ||= 3 %>
<% name_field ||= :name %>
<% separator ||= false %>
<% view_all ||= root_path %>

<% if separator %>
  <% items.limit(limit).each_with_index do |item, index| %>
    <%= separator unless index.zero? %>
    <%= link_to item.send(name_field), item %>
  <% end %>
<% else %>
  <ul class="list-unstyled mb-0">
    <% items.limit(limit).each do |item| %>
      <li><%= link_to item.send(name_field), item %></li>
    <% end %>
  </ul>
<% end %>

<% if items.empty? %>
  无
<% elsif items.size > 3 %>
  <%= separator %>
  &hellip;
  <br />
  共 <%= items.size %> 个，<%= link_to '查看全部', view_all %>
<% end %>
```

该列表列出了默认前 3 个对象，并在总数超过该默认值时显示总数及一个「查看全部」的链接。

卡片脚部为【编辑】（当前对象）、【返回】和【删除】三个按钮，其中在不适用的场合下【编辑】和【删除】按钮可能不存在，例如贷款的详细信息页面，当贷款状态为「发放中」时。这些按钮的功能都使用 Rails 自带的库实现。

#### 3.3.6 创建 / 编辑表格

模型表格使用 Rails 自带的 Action View Forms 实现，在新建对象时能够自动填充为默认值，在编辑对象时能够自动填充为当前值。下面以支行的编辑表格 `branches/_form.html.erb` 为例展示：

```erb
<%= form_with model: branch, local: true, class: 'my-3' do |form| %>
  <%= render partial: 'error_explanation', locals: { model: branch } %>

  <div class="form-group">
    <%= form.label :name %>
    <%= form.text_field :name, class: 'form-control' %>
  </div>

  <div class="form-group">
    <%= form.label :city %>
    <%= form.text_field :city, class: 'form-control' %>
  </div>

  <div class="form-group">
    <%= form.label :assets %>
    <%= form.number_field :assets, step: 0.01, class: 'form-control' %>
  </div>

  <div class="actions">
    <%= form.submit class: 'btn btn-success' %>
  </div>
<% end %>
```

其中账户的新建页面有个别选项会随「账户类型」的选择而变化，且「账户类型」选项在编辑时是不可修改的。该功能使用 Vue.js 实现，相关部分代码如下：

```erb
<%= form_with model: account, local: true, id: 'account-form', class: 'my-3' do |form| %>
  <div class="form-group">
    <%= form.label :accountable_type %>
    <%= form.select :accountable_type, options_for_select(%w[储蓄账户 支票账户].zip(%i[DepositAccount CheckAccount]), account.accountable_type), {}, { class: 'form-control', 'v-model': 'accountType', disabled: !account.new_record? } %>
  </div>

  <% if account.new_record? || account.accountable_type == 'DepositAccount' %>
    <div class="row" v-if="accountType === 'DepositAccount'">
      <%= form.fields_for :accountable, (account.new_record? ? DepositAccount.new : account.accountable) do |f| %>
        <div class="form-group pr-sm-0 col">
          <%= f.label :interest_rate %>
          <%= f.number_field :interest_rate, step: :any, class: 'form-control' %>
        </div>
        <div class="form-group col col-12 col-sm-4 col-lg-3 col-xl-2">
          <%= f.label :currency %>
          <%= f.text_field :currency, class: 'form-control', maxlength: 3, value: f.object.currency.upcase, style: 'font-family: Consolas, monospace; text-transform: uppercase;' %>
        </div>
      <% end %>
    </div>
  <% end %>

  <% if account.new_record? || account.accountable_type == 'CheckAccount' %>
    <div v-if="accountType === 'CheckAccount'">
      <%= form.fields_for :accountable, (account.new_record? ? CheckAccount.new : account.accountable) do |f| %>
        <div class="form-group">
          <%= f.label :withdraw_amount %>
          <%= f.number_field :withdraw_amount, step: 0.01, class: 'form-control' %>
        </div>
      <% end %>
    </div>
  <% end %>

  <% content_for :body_after do %>
    <script type="text/javascript">
      var app = new Vue({
        el: '#account-form',
        data: {accountType: document.querySelector('[v-model="accountType"]').value}
      });
    </script>
  <% end %>
<% end %>
```

#### 3.3.7 关联信息列表页面

该页面用于

- 支行的关联员工、账户、贷款
- 部门的关联员工
- 员工的关联客户

使用一个 `<div>` 标签列出全部项目，每个项目自己占据一行，代码如下：

```erb
<% name_field ||= :name %>

<% content_for :heading do %>
  <h1 class="mb-0"><%= title heading %></h1>
<% end %>

<% content_for :body do %>
  <div class="list-group list-group-flush my-0">
    <% items.each do |item| %>
      <%= link_to item.send(name_field), item, class: 'list-group-item list-group-item-action' %>
    <% end %>
  </div>
<% end %>

<% content_for :footer do %>
  <%= link_to raw(t'actions.back'), back_to, class: 'btn btn-primary' %>
<% end %>

<%= render template: 'layouts/listing' %>
```

#### 3.3.8 账户的关联客户页面

账户的关联客户页面与 3.3.7 节所述的关联信息列表页面不同，使用一个完整的 table 以列出额外信息，如客户访问账户的时间等。另外主卡片下方还有一个额外卡片，作为「添加新关联客户」的表格。代码 `accounts/owners.html.erb` 如下：

```erb
<% content_for :heading do %>
  <h1 class="mb-0"><%= title "账户 \##{@account.id} 的关联客户" %></h1>
<% end %>

<% content_for :body do %>
  <table class="table table-hover mb-0 with-action">
    <thead>
      <tr>
        <th>客户</th>
        <th>最近访问时间</th>
        <th>操作</th>
      </tr>
    </thead>

    <tbody>
      <% @owners.each do |owner| %>
        <tr>
          <td><%= link_to owner.client_name, clients_path(owner.client_id) %></td>
          <td><%= owner.last_access %></td>
          <td>
            <%= link_to raw(t'actions.destroy'), destroy_account_owner_path(@account, owner.client_id), method: :delete, class: 'text-danger', data: { confirm: t('confirm') } %>
          </td>
        </tr>
      <% end %>
    </tbody>
  </table>
<% end %>

<% content_for :footer do %>
  <%= link_to raw(t'actions.back'), @account, class: 'btn btn-primary' %>
<% end %>

<% content_for :after do %>
  <% if @available_clients.empty? %>
    <div class="my-3">
      <p>无客户可添加</p>
    </div>
  <% else %>
    <%= form_with url: new_account_owner_path, local: true, class: 'my-3' do |form| %>
      <div class="card">
        <div class="card-header">
          <h3 class="my-0">新增客户</h3>
        </div>
        <div class="card-body">
          <%= render partial: 'error_explanation', locals: { model: @account } %>

          <div class="form-group">
            <%= form.fields_for :ownerships, Ownership.new do |f| %>
              <%= f.label :client_id, '新增关联客户' %>
              <%= f.select :client_id, options_from_collection_for_select(@available_clients, :id, :name), {}, { class: 'form-control' } %>
            <% end %>
          </div>
        </div>

        <div class="card-footer">
          <%= form.submit '添加客户', class: 'btn btn-success' %>
        </div>
      </div>
    <% end %>
  <% end %>
<% end %>

<%= render template: 'layouts/listing' %>
```

其中选择新关联客户的下拉选单仅显示可正常添加的客户（不存在冲突账户的客户），其产生逻辑见 3.2.7 节。

#### 3.3.9 「业务统计」页面

业务统计页面包含两个大卡片，分别列出储蓄业务概览数据及贷款业务概览数据，内容参见 3.2.11 节，代码 `stats/index.html.erb` 如下：

```erb
<% card_class = 'shadow flex-grow-1 px-0 mb-4' %>
<% dl_class = 'row mb-0' %>
<% dt_class = 'col col-6 px-2 text-right' %>
<% dd_class = 'col col-6 px-2' %>

<%= render partial: 'svg_header', locals: { file: 'combo-chart.svg', text: title('数据统计') } %>

<div class="row d-flex flex-column flex-md-row">
  <div class="col col-12 col-md-6 d-flex flex-column flex-grow-1">
    <div class="card <%= card_class %>">
      <div class="card-header text-center bg-success text-light">
        <h3 class="mb-0 font-weight-normal">储蓄业务</h3>
      </div>

      <div class="card-body pb-3">
        <dl class="<%= dl_class %>">
          <% @deposit_card_content.each do |dt, dd| %>
            <dt class="<%= dt_class %>"><%= dt %></dt>
            <dd class="<%= dd_class %>"><%= dd %></dd>
          <% end %>
        </dl>
      </div>

      <div class="card-footer text-center bg-success text-light">
        <%= link_to raw(t'actions.info'), deposit_stats_path, class: 'btn btn-primary' %>
      </div>
    </div>
  </div>

  <div class="col col-12 col-md-6 d-flex flex-column flex-grow-1">
    <div class="card <%= card_class %>">
      <div class="card-header text-center bg-danger text-light">
        <h3 class="mb-0 font-weight-normal">贷款业务</h3>
      </div>

      <div class="card-body pb-3">
        <dl class="<%= dl_class %>">
          <% @loan_card_content.each do |dt, dd| %>
            <dt class="<%= dt_class %>"><%= dt %></dt>
            <dd class="<%= dd_class %>"><%= dd %></dd>
          <% end %>
        </dl>
      </div>

      <div class="card-footer text-center bg-danger text-light">
        <%= link_to raw(t'actions.info'), loan_stats_path, class: 'btn btn-primary' %>
      </div>
    </div>
  </div>
</div>
```

其中 `svg_header` 为一个小部件，用于在标题前面添加图标，以便美观，其代码如下：

```erb
<h1 class="text-center py-4 py-md-5 display-4 d-sm-flex justify-content-center">
  <span class="d-block d-sm-inline pb-4 pb-sm-0">
    <%= svg_tag file, class: 'svg-inline svg-xl zero-width' %>
  </span>
  <%= text %>
</h1>
```

#### 3.3.10 业务统计的搜索页面

该搜索页面由「储蓄业务」和「贷款业务」两页面共用，因此提取为 `stats/_common.html.erb`：

```erb
<% content_for :head do %>
  <%# Chart libraries %>
  <%= javascript_include_tag "https://cdn.jsdelivr.net/npm/chartkick@3.2.0/dist/chartkick.min.js", integrity: "sha256-QQ42jSsvKp0SDBvW+xRjHWfK2I4ObL37tEF4+l8a0qg=", crossorigin: :anonymous %>
  <%= javascript_include_tag "https://cdn.jsdelivr.net/npm/chart.js@2.9.3/dist/Chart.min.js", integrity: "sha256-R4pqcOYV8lt7snxMQO/HSbVCFRPMdrhAFMH+vr9giYI=", crossorigin: :anonymous %>
<% end %>

<%= render partial: 'svg_header', locals: { file: title_svg, text: title_text } %>

<%= render partial: 'search_form', locals: { url: current_path } %>

<% if @action %>
  <div class="card shadow">
    <div class="card-header text-center bg-primary text-white">
      <h3 class="mb-0">搜索结果</h3>
    </div>
    <div class="card-body rounded-bottom bg-white p-3">
      <ul class="nav nav-tabs" id="branches-tabs" role="tablist">
        <% @data_branches.each_with_index do |record, index| %>
          <% branch_id = record.branch_id %>
          <li class="nav-item" role="presentation">
            <a class="nav-link <%= 'active' if index.zero? %>" id="tab-branch-<%= branch_id %>" data-toggle="tab" href="#branch-<%= branch_id %>" role="tab" aria-controls="branch-<%= branch_id %>" aria-selected="<%= index.zero? %>">
              <%= record.branch_name %>
            </a>
          </li>
        <% end %>
      </ul>
      <div class="tab-content" id="branches">
        <% @data_branches.each_with_index do |record, index| %>
          <% branch_id = record.branch_id %>
          <% records = @query.where(branch_id: branch_id) %>
          <div class="tab-pane fade <%= 'show active' if index.zero? %>" id="branch-<%= branch_id %>" role="tabpanel" aria-labelledby="tab-branch-<%= branch_id %>">
            <table class="table table-hover border border-top-0">
              <thead>
                <tr>
                  <th class="border-top-0">时间</th>
                  <th class="border-top-0">客户数</th>
                  <th class="border-top-0">业务额</th>
                </tr>
              </thead>

              <tbody>
                <% records.each do |record| %>
                  <tr>
                    <td><%= record.display_time %></td>
                    <td><%= record.clients_count %></td>
                    <td><%= currency_value record.total_amount %></td>
                  </tr>
                <% end %>
              </tbody>
            </table>

            <div class="row">
              <div class="col col-12 col-md-6">
                <%= column_chart stats_amount_chart records %>
              </div>
              <div class="col col-12 col-md-6">
                <%= column_chart stats_clients_chart records %>
              </div>
            </div>
          </div>
        <% end %>
      </div>
    </div>
  </div>
<% end %>
```

其中搜索结果使用 `<table>` 列出表格，使用 [Chartkick 插件](https://chartkick.com/)（后端采用 [Chart.js](https://www.chartjs.org/)）绘制图表。由于 Chart.js 对曲线图表有额外的技术限制难以绕过，因此此处待用了柱状图表。此处绘制两个图表，分别展示总金额和总客户数。

搜索表格代码如下：

```erb
<% @date_options ||= { date_separator: '</div><div class="col col-4">', start_year: @start_year, end_year: @end_year } %>

<%= form_with url: url, local: true, id: 'search-form', method: :get, class: 'card shadow mb-3' do |form| %>
  <div class="card-header text-center bg-info text-white">
    <h3 class="mb-0">搜索<h3>
  </div>

  <div class="card-body">
    <div class="form-group">
      <%= form.label :branch_ids, '支行' %>
      <%= form.hidden_field :branch %>
      <%= form.select :branch_ids, options_from_collection_for_select(Branch.select(:id, :name), :id, :name, @branches), { include_hidden: false }, { class: 'form-control', multiple: true } %>
    </div>

    <div class="form-group">
      <%= form.label :start_date, '开始日期' %>
      <%= form.hidden_field :start_date %>
      <div class="form-row">
        <div class="col col-4">
          <%= form.date_select :start_date, @date_options.merge({ default: @start_date }), { class: 'form-control' } %>
        </div>
      </div>
    </div>

    <div class="form-group">
      <%= form.label :end_date, '结束日期' %>
      <%= form.hidden_field :end_date %>
      <div class="form-row">
        <div class="col col-4">
          <%= form.date_select :end_date, @date_options.merge({ default: @end_date }), { class: 'form-control' } %>
        </div>
      </div>
    </div>

    <div class="form-group mb-0">
      <%= form.label :time_span, '按时间归类' %>
      <div class="col-12">
        <% @time_spans.each do |name, value| %>
          <div class="form-check form-check-inline">
            <%= form.radio_button :time_span, value, checked: (@time_span == value), class: 'form-check-input' %>
            <%= form.label :time_span, name, value: value, class: 'form-check-label' %>
          </div>
        <% end %>
      </div>
    </div>
  </div>

  <div class="card-footer text-center bg-info text-white">
    <%= form.button class: 'btn btn-success', type: :submit, name: :action, value: :submit, onclick: 'onSubmit()' do %>
      <i class="fa fas fa-search"></i> 搜索
    <% end %>
    <%= link_to raw(t'actions.back'), stats_path, class: 'btn btn-secondary' %>
  </div>
<% end %>

<%= javascript_include_tag 'search-form', async: true %>
```

该表格使用 GET 方法发送，以确保所有搜索结果链接可复用。另外该模块包含了一个自己写的帮助脚本，其内容如下：

```javascript
function onSubmit(e) {
  $('#branch').val($('#branch_ids').val().join(" "));
  $('#branch_ids').removeAttr('name');

  $.each(["start_date", "end_date"], function(index, id) {
    var a = [], elem;
    for (var i = 1; i <= 3; i++) {
      elem = $("#_" + id + "_" + i + "i");
      a[i] = elem.val();
      elem.removeAttr('name');
    }
    var date = new Date(Date.UTC(a[1], a[2] - 1, a[3])); // 2nd parameter is monthIndex
    console.log(date.toISOString());
    $("#" + id).val(date.toISOString().slice(0, 10));
  });

  $('#search-form input').each(function(index) {
    var item = $(this);
    if (!item.val() || item.val() == 'none') {
      item.removeAttr('name');
    }
  });
}
```

其作用为

- 从原始的输入框中去掉 `name` 属性，因为该属性是由 Rails 的 Form Helper 生成的，格式不美观
- 将支行选择用逗号连接作为查询参数
- 将日期输入拼接成 ISO 8601 的日期格式作为查询参数

使用该脚本可以生成美观的查询 URL。

### 3.4 Sprockets Assets Pipeline

本项目的主要前端功能都使用 jQuery，Bootstrap，Rails UJS 和 Vue.js 实现，但也包含少量了自定义代码，因此使用 [Sprockets](https://github.com/rails/sprockets) 作为 Assets Pipeline 来编译打包这些额外代码。

Sprockets 的配置文件 `/app/assets/config/manifest.js` 内容如下：

```javascript
//= link_tree ../images
//= link_directory ../javascripts .js
//= link application.css
```

在生产环境中一般不随时从源码编译，而是在部署前一次性提前编译好，减少生产环境服务器的重复工作。预编译使用 Rake 任务 `assets:precompile` 完成，该操作在打包 Docker 镜像前也会执行，因为 Docker 镜像内为生产环境。

#### 3.4.1 JavaScript 脚本

本项目使用了两段自定义 JavaScript 脚本，分别在 3.3.4 节和 3.3.10 节介绍。该脚本使用原生 JavaScript 语法编写，使用 Sprockets 编译打包，并在 Action View 模板中使用 `javascript_include_tag` 调用。Sprockets 会自动在生成的文件的文件名部分末尾添加一段 hash，这样当源文件修改时生成的文件名也会变化，可以省去清除浏览器缓存的必要。

#### 3.4.2 CSS 样式表

本项目使用了多段自定义 CSS 样式表，采用 [SCSS](https://sass-lang.com/) 语法书写，使用 [SassC](https://github.com/sass/sassc-ruby) 编译为正统的 CSS 语法并最小化（minify）。该过程同样借助 Sprockets 自动化，详见 3.4.1 节。

与 JavaScript 不同，本项目所使用的全部 CSS 打包到一个文件 `application.css` 内，避免不同页面加载不同文件带来的额外网络开销和延迟。主文件的源文件 `application.scss` 仅包含一行有效代码：

```scss
//= require_tree .
```

该代码指示包含（include）当前目录下全部 CSS / SCSS 格式文件。

#### 3.4.3 图片

本项目使用了多个 SVG 矢量图作为图标等，并使用一个 PNG 文件作为网站图标（favicon），它们同样由 Sprockets 编译打包，过程与 3.4.1 节所述 JavaScript 的打包流程相同，此处不再重复。

## 4 实现与测试

### 4.1 实现结果

#### 首页

![首页]({{ page.image_prefix }}/home.png){: .border }

#### 支行列表页面

![支行列表页面]({{ page.image_prefix }}/branches-index.png){: .border }

#### 支行详细信息页面

![支行详细信息页面]({{ page.image_prefix }}/branches-show.png){: .border }

#### 账户编辑页面

![账户编辑页面]({{ page.image_prefix }}/accounts-edit.png){: .border }

#### 支行的关联账户页面

![支行的关联账户页面]({{ page.image_prefix }}/branches-accounts.png){: .border }

#### 账户的关联客户页面

![账户的关联客户页面]({{ page.image_prefix }}/accounts-owners.png){: .border }

#### 贷款的支付页面

![贷款的支付页面]({{ page.image_prefix }}/loans-issues.png){: .border }

#### 「业务统计」页面

![业务统计页面]({{ page.image_prefix }}/stats.png){: .border }

#### 业务统计的搜索页面

![业务统计的搜索页面]({{ page.image_prefix }}/stats-search.png){: .border }

![业务统计的搜索结果页面]({{ page.image_prefix }}/stats-search-results.png){: .border }

以上即为本系统的实现结果（外观）。

### 4.2 测试结果

#### 4.2.1 操作成功结果

##### 创建支行

![创建支行]({{ page.image_prefix }}/branches-create.png){: .border }

##### 更新支行

![更新支行]({{ page.image_prefix }}/branches-update.png){: .border }

##### 删除支行

![删除支行]({{ page.image_prefix }}/branches-destroy.png){: .border }

##### 账户新增关联客户

![账户新增关联客户]({{ page.image_prefix }}/ownerships-create.png){: .border }

##### 贷款新增支付

![贷款新增支付]({{ page.image_prefix }}/issues-create.png){: .border }

#### 4.2.2 操作失败结果

##### 创建支行

![创建支行]({{ page.image_prefix }}/branches-create-fail.png){: .border }

##### 删除支行

![删除支行]({{ page.image_prefix }}/branches-destroy-fail.png){: .border }

##### 更新账户

修改开户支行

![更新账户]({{ page.image_prefix }}/accounts-edit-fail.png){: .border }

错误的账户余额

![更新账户]({{ page.image_prefix }}/accounts-edit-fail-2.png){: .border }

##### 贷款支付

![贷款支付]({{ page.image_prefix }}/issues-create-fail.png){: .border }

若修改前端强行提交不正确的数值

![贷款支付]({{ page.image_prefix }}/issues-create-fail-2.png){: .border }

以上即为本系统的测试结果，其表明本系统具有符合正常逻辑的错误检查。

## 5 总结与讨论

本人自 2018 年[初次接触 Ruby on Rails](https://github.com/Charcoal-SE/metasmoke) 以来，一直想要找个机会通过自己编写一个完整项目来熟悉这个框架，正好本次实验是一个绝佳的机会，因此决定采用 Ruby on Rails 作为完成本实验的框架。由于几乎是零基础（Ruby 语言除外），同时使用了最新的版本（Rails 6.0.3），而网上的大部分资料及手头的一本教程书籍都是讲 Rails 5 甚至 Rails 4/3 的，也遇到了不少新旧版本不一致的坑，导致 Rails 5 以前的解决方案不适用，前期花了大量时间在 Google 及 Stack Overflow 上，这从本人的浏览器历史记录里就可以看出：

![Browser History]({{ page.image_prefix }}/browser-history.png)

整体体验看来，得益于 Ruby 语言灵活的设计，Ruby on Rails 是最方便快捷的 Web 框架（显然它的性能比不上 Go 和 PHP 等语言），相比其他同学动辄上千行的 `views.py`，我只用了不到 700 行 Ruby 就实现了全部控制器功能，并且额外实现了支行、部门和员工的增删改查（这是实验文档里所没有要求的功能），甚至其中一半左右的代码都是框架代码（由 `rails generate` 命令生成的“默认”代码）和空行。

![Word Count on Controllers]({{ page.image_prefix }}/wc-controllers.png)

同样由于 Ruby 语言方便的设计，Action View 视图模板的整体体验也比 Django + Jinja2 要好，所有变量只要写入类实例变量（class instance variables，`@var`），就自动在 ERB 模板中可用。同时 Rails 的 Action View 模板中还可以无缝使用各种自带的及自己编写的帮助函数（helper methods），这更进一步减少了重复工作。

再一次受益于 Ruby 语言的优势，Rails 的一些周边配置文件也十分简洁灵活，例如控制器的路由配置：

```ruby
Rails.application.routes.draw do
  root 'stats#home'
  get '/about', to: 'stats#about', as: :about

  resources :branches
  resources :departments
  resources :staffs
  resources :clients
  resources :accounts
  resources :loans, except: %i[edit update]

  scope :branches do
    get ':id/staffs', to: 'branches#staffs', as: :branch_staffs
    get ':id/accounts', to: 'branches#accounts', as: :branch_accounts
    get ':id/loans', to: 'branches#loans', as: :branch_loans
  end

  # ...
end
```

对比一个典型 Django 项目的路由配置 `urls.py`：

```python
from django.urls import path, reverse_lazy
from django.views.generic import TemplateView
from django.contrib.auth import views as auth_views
from . import views


urlpatterns = [
    path('', TemplateView.as_view(template_name="app/index.html"), name='index'),
    path('login/', auth_views.LoginView.as_view(template_name='app/login.html'), name='login'),
    path('logout/', views.user_logout, name='logout'),
    # 此处省略 60+ 行，每行都很长
]
```

可见 Ruby 及 Ruby on Rails 宣称的 convention over configuration 确实大大减少了开发工作量，但同时带来的一个难点是开发者需要熟悉 Rails 的这些 convention。显然，稍微熟悉 Rails 之后，这些“难点”并不是什么实际的问题，甚至 Stack Overflow 上标签 `ruby-on-rails` 的问题比标签 `ruby` 的问题还要多一半：

![Stack Overflow Tags]({{ page.image_prefix }}/so-tags.png)

因此我认为，Ruby on Rails 是一个对开发者友好、对用户也友好、同时又功能强大的 web 框架，适合作为敏捷开发 web 应用程序的**首选**。

---

作为对比，本实验的实验报告模板**极为冗长**，不仅要求重复实验文档中已有的内容，如系统目标和需求说明等，还要求绘制一大堆麻烦又没有意义的结构图流程图，并且说明一些毫无意义的细节（如各模块的输入、输出和程序流程图等）。此报告将本实验的整体体验结构拉到了一个十分科学的平衡点，即著名的[八二法则](https://zh.wikipedia.org/wiki/%E5%B8%95%E7%B4%AF%E6%89%98%E6%B3%95%E5%88%99)：实验中 80% 的汗水带来了 20% 的痛苦（编写应用程序本身），而 20% 的汗水带来了 80% 的痛苦🤮（撰写实验报告）。本报告之所以能够写得如此详细尽致，不仅在于找准了写报告之道，关键在于找准了写报告之道。

因此，本实验最亟需改进的地方，甚至可能是唯一需要改进的地方，就是**将这份又臭又长的实验报告模板扔掉**，为做实验的学生们，也为读实验报告的助教们减轻大量不必要的负担。

本报告至此基本结束了，已近一万七千字，在此诚挚地向完整仔细阅毕本报告的各位助教们道一句：**辛苦了**，并恳请助教仔细考虑复杂繁长的实验报告的必要性，**谢谢助教**。