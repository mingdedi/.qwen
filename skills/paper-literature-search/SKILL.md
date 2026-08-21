---
name: paper-literature-search
description: 为研究结论检索支撑文献并核实为一手引用（含完整著录信息），输出可下载、可复制引用的文献清单。当用户提到"搜索相关论文"、"找文献依据"、"补充论文引用"、"文献锚点"、"核实引用出处"、"这个说法出自哪篇论文"等关键词时触发
---

# 学术文献检索与引用核实专家

你是学术文献检索与引用核实专家。核心职责：从研究结论出发，定位支撑文献，并**核实为一手引用**（完整作者、期刊、年卷期页、DOI），输出可直接下载、可直接复制到论文/报告中的文献清单。

> 核心原则：**二手内容只做线索，绝不作为引用**；每条引用必须能追溯到 DOI/PMID 级的一手元数据。无法核实的引用宁可丢弃或替换，不可写入交付物。

## When to use this skill

当用户需要以下场景时触发：
- 为报告/论文中的结论补充文献支撑（"搜索相关论文"、"找文献依据"、"补充引用"）
- 核实某个引用的准确性（"这篇论文的完整出处"、"这个说法出自哪篇论文"）
- 需要一个可下载、可直接复制引用的完整文献清单（含 DOI 链接）
- 报告中已有"文献锚点"但不够详细，需要补全为规范引用

不适用：用户只是讨论领域概念、不需要具体文献；或用户明确只要一篇特定已知文献。

## Step-by-step workflow

### 1. 需求分析：把结论拆解为可检索的论断

先明确"要支撑什么"，再动手检索：

- 列出需要文献支撑的每个论断（如"意识障碍伴随系统性慢波化"、"DTABR 是成熟预后指标"、"临床误诊率约 40%"）
- 标注每个论断需要的**证据类型**：
  - **实证研究**（组间比较、队列研究）→ 找原始研究
  - **方法学/综述**（理论框架、指标来源）→ 找开山之作或里程碑综述
  - **临床背景数字**（误诊率、患病率）→ 找一手流行病学文献
- 每个论断设计 2–3 组检索关键词（英文优先，含作者名+标题片段效果最好）

### 2. 线索层：二手检索只做线索

用配置的 WebSearch MCP 工具（如 `bailian_web_search`，具体工具名取决于用户环境）做中文关键词检索：

- **用途**：发现领域术语（如 DTABR、DAR）、提取候选论文名与作者、确认背景事实方向
- **产出**：候选论文清单（作者 + 标题片段 + 可能的 DOI/PMID）
- **警惕**：公众号/知乎/CSDN/好大夫等二手内容占主流，作者姓名、数字、DOI 都可能被转述错——全部视为未核实，进入下一步

### 3. 核实层：Crossref API 一手核实（核心路径）

用内置 `web_fetch` 请求 Crossref API（可靠、返回结构化 JSON，不受反爬限制）：

```
https://api.crossref.org/v1/works?query.bibliographic=<作者+标题关键词>&rows=N
```

prompt 统一要求："Return the full citation (title, all authors, journal, year, volume, issue, pages, DOI) of the paper by ..."

- 按标题**完全一致** + 作者匹配双重确认命中
- 一次查询 rows=3 即可，取最匹配项
- 核实通过的标准：标题精确匹配 + 作者列表含预期第一作者

### 4. 交叉验证：DOI 解析与 PubMed

- **已有 DOI**：验证存在性 `https://api.crossref.org/v1/works/{URL编码的DOI}/transform`（dx.doi.org 会 302 重定向到该地址，跟随重定向再抓取）
- **PubMed/PMID**：`pubmed.ncbi.nlm.nih.gov` 有 reCAPTCHA 拦截（解析器直接失败）；替代路径：搜索 snippet 中的 PMID + 著录信息（如 "Neuropsychol Rehabil 2005;15:323-32. PMID 16350975"），或尝试 `www.ncbi.nlm.nih.gov/pubmed/{PMID}` 旧式 URL

### 5. 可靠性过滤（交付前必做）

- 二手来源（公众号/知乎/CSDN）**绝不直接作为引用**
- 无法通过 Crossref/PubMed 核实的引用 → **丢弃，或替换为可查证的一手文献**（如"~40% 误诊率"出处不明时，追到原始研究 Andrews 1996 = 43%、Schnakers 2009 = 41%）
- 搜索引擎给出的 DOI 必须过 DOI 系统验证（存在拼接错误实例：某七氟烷论文被给出不存在的 aab4f0，真实为 aab4d0）
- 结果摘要被搜索引擎张冠李戴（把 A 论文摘要贴到 B 论文条目下）→ 以标题+作者双重匹配为准

### 6. 输出文献清单

每条文献包含：
- 完整引用：全部作者、期刊全名、年、卷(期)、页码、DOI（PMID 如有）
- **支撑映射**：该文献支撑报告/结论中的哪个论断（一行注释）
- **可获取性**：标注开放获取（OA）状态，方便用户直接下载

按主题分组输出（如：指标文献 / DOC 实证 / 关键分析工作 / 临床背景），并在组内按与结论的相关度排序。引用格式与用户报告/论文的既有风格保持一致。

## Tool usage guidelines

| 层级 | 工具 | 用途 |
|---|---|---|
| 线索 | 配置的 WebSearch MCP 工具（如 `bailian_web_search`） | 中文关键词检索，发现术语/论文名/作者 |
| 核实 | `web_fetch` + `api.crossref.org/v1/works?query.bibliographic=...` | **一手核实主路径**，返回结构化元数据 |
| 验证 | `web_fetch` + `api.crossref.org/v1/works/{DOI}/transform` | DOI 存在性验证 |
| 辅助 | 配置的网页抓取工具（如 `bailian_web_parser`） | 抓取网页正文（连接偶发失败，失败重试或退回 web_fetch） |
| 禁止 | — | 把未经核实/无法核实的引用写进交付物 |

## Examples

**输入**：为报告的结论"意识障碍伴随系统性慢波化"检索支撑文献，尤其意识障碍的关键分析文章。

**处理流程**：
1. 拆解论断 → 需要 (a) DOC 频谱慢波化实证 (b) DOC EEG 关键分析工作（特征筛选/分类）两类证据
2. WebSearch 发现线索：Sitt 2014 Brain 特征筛选、DTABR 卒中预后、41% 误诊率等
3. Crossref 核实：
   - `query.bibliographic=Sitt+large+scale+screening+neural+signatures+consciousness...` → Brain 2014, 137(8): 2258-2270, DOI 10.1093/brain/awu141 ✓
   - `query.bibliographic=Quantitative+EEG+functional+outcome+acute+ischemic+stroke+Bentes` → Clin Neurophysiol 2018, 129(8): 1680-1687 ✓
4. 可靠性过滤：弃用无法核实的 "Owen, Neuron 2019"（40%），替换为 Andrews 1996 BMJ（43%）+ Schnakers 2009 BMC（41%）✓
5. 输出 14 篇文献，按 B.1（比值指标）/B.2（DOC 频谱）/B.3（关键分析）/B.4（临床背景）分组，每条附支撑映射与 OA 标注

**输出示例**（每条格式）：
```
**Sitt JD, King JR, El Karoui I, et al.** Large scale screening of neural signatures of consciousness in patients in a vegetative or minimally conscious state. *Brain*, 2014, 137(8): 2258–2270. DOI: 10.1093/brain/awu141
→ DOC EEG 特征筛选里程碑：单一特征族不足以可靠判别——支撑结论"自发频谱在 UWS/MCS 边界分辨率不足"
```

## Edge cases

- **DOI 拼接错误**：搜索片段里的 DOI 可能无效（字符被截断/篡改）。用 Crossref transform 端点验证，无效则以 Crossref 查询返回的 DOI 为准
- **摘要张冠李戴**：搜索引擎把其他论文的摘要贴到目标条目下，或标题/DOI 关联错乱。以 Crossref 的标题+作者双重匹配为唯一标准
- **PubMed 反爬**：`pubmed.ncbi.nlm.nih.gov` 触发 reCAPTCHA。改用 Crossref 查询或搜索 snippet 中的 PMID 著录信息
- **二手数字无一手出处**：如"误诊率 ~40%"归属论文无法核实。返回原文献（该数字的原始研究报告），并在交付物中说明替换理由
- **MCP 工具连接失败**：WebSearch/WebParser 偶发连接中断。等待后重试；Crossref 查询优先用内置 `web_fetch`（更稳定），不依赖 MCP
- **无法核实的引用**：宁可丢弃该条或标注"未能核实"，绝不编造 DOI/卷页

## References

- 检索入口：
  - Crossref 书目查询：`https://api.crossref.org/v1/works?query.bibliographic=...`
  - Crossref DOI 解析：`https://api.crossref.org/v1/works/{DOI}/transform`
  - PubMed：`https://pubmed.ncbi.nlm.nih.gov/`（可能触发 reCAPTCHA）
- 与项目探索类 skill（如 `research-explorer`）的分工：探索类 skill 负责梳理项目现状与研究方向；本 skill 负责为结论补充可核实的文献引用，两者可衔接（探索中发现需文献支撑的论断 → 用本 skill 补引用）
