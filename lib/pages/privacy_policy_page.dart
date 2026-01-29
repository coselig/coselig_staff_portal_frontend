import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('隱私權政策'),
        backgroundColor: Colors.orangeAccent[100],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '隱私權政策',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text('最後更新：2026年1月29日'),
            const SizedBox(height: 16),
            const Text(
              '本隱私權政策描述了我們在您使用服務時收集、使用和披露您的信息的政策和程序，並告訴您您的隱私權利以及法律如何保護您。',
            ),
            const SizedBox(height: 16),
            const Text(
              '我們使用您的個人數據來提供和改進服務。通過使用服務，您同意根據本隱私權政策收集和使用信息。本隱私權政策是使用隱私權政策生成器創建的。',
            ),
            const SizedBox(height: 24),

            // 解釋和定義
            const Text(
              '解釋和定義',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              '解釋',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '首字母大寫的詞語在以下條件下具有定義的含義。以下定義無論是單數還是複數形式出現，都具有相同含義。',
            ),
            const SizedBox(height: 16),

            const Text(
              '定義',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text('就本隱私權政策而言：'),
            const SizedBox(height: 8),

            _buildDefinitionItem('帳戶', '為您創建的唯一帳戶，用於訪問我們的服務或服務的部分。'),
            _buildDefinitionItem('關聯公司', '控制一方、受一方控制或與一方共同控制的實體，其中"控制"意味著擁有有權選舉董事或其他管理機構的50%或更多股份、股權利益或其他證券。'),
            _buildDefinitionItem('應用程式', '光悅員工系統，由公司提供的軟體程式。'),
            _buildDefinitionItem('公司', '（在本隱私權政策中稱為"公司"、"我們"、"我們"或"我們的"）指光悅科技股份有限公司，后庄七街215號。'),
            _buildDefinitionItem('Cookie', '網站放置在您的電腦、移動設備或其他任何設備上的小文件，包含您在該網站上的瀏覽歷史記錄等詳細信息。'),
            _buildDefinitionItem('國家', '指：台灣'),
            _buildDefinitionItem('設備', '任何可以訪問服務的設備，如電腦、手機或數字平板。'),
            _buildDefinitionItem('個人數據', '（或"個人信息"）與已識別或可識別個人相關的任何信息。我們交替使用"個人數據"和"個人信息"，除非法律使用特定術語。'),
            _buildDefinitionItem('服務', '指應用程式或網站或兩者。'),
            _buildDefinitionItem('服務提供商', '代表公司處理數據的任何自然人或法人。它指公司僱用的第三方公司或個人，以促進服務、代表公司提供服務、執行與服務相關的服務，或協助公司分析服務的使用方式。'),
            _buildDefinitionItem('使用數據', '自動收集的數據，由服務的使用產生，或來自服務基礎設施本身（例如，頁面訪問的持續時間）。'),
            _buildDefinitionItem('網站', '光悅員工系統，可從 https://employeeservice.coseligtest.workers.dev 訪問。'),
            _buildDefinitionItem('您', '訪問或使用服務的個人，或代表該個人訪問或使用服務的公司或其他法律實體（如適用）。'),

            const SizedBox(height: 24),

            // 收集和使用您的個人數據
            const Text(
              '收集和使用您的個人數據',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              '收集的數據類型',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              '個人數據',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '在使用我們的服務時，我們可能會要求您提供某些可用于聯繫或識別您的個人識別信息。個人識別信息可能包括但不限於：',
            ),
            const SizedBox(height: 8),
            const Text('• 電子郵件地址'),
            const SizedBox(height: 16),

            const Text(
              '使用數據',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text('使用數據在使用服務時自動收集。'),
            const SizedBox(height: 8),
            const Text(
              '使用數據可能包括您的設備的互聯網協議地址（例如IP地址）、瀏覽器類型、瀏覽器版本、您訪問的我們服務的頁面、您的訪問時間和日期、在這些頁面上花費的時間、唯一設備識別符和其他診斷數據等信息。',
            ),
            const SizedBox(height: 8),
            const Text(
              '當您通過移動設備訪問服務時，我們可能會自動收集某些信息，包括但不限於您使用的移動設備類型、您的移動設備的唯一ID、您的移動設備的IP地址、您的移動操作系統、您使用的移動互聯網瀏覽器類型、唯一設備識別符和其他診斷數據。',
            ),
            const SizedBox(height: 8),
            const Text(
              '我們還可能收集您的瀏覽器在您訪問我們的服務或通過移動設備訪問服務時發送的信息。',
            ),
            const SizedBox(height: 16),

            const Text(
              '跟踪技術和Cookie',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '我們使用Cookie和類似的跟踪技術來跟踪我們服務上的活動並存儲某些信息。我們使用的跟踪技術包括信標、標籤和腳本，用於收集和跟踪信息以及改進和分析我們的服務。我們使用的技術可能包括：',
            ),
            const SizedBox(height: 8),
            const Text('• Cookie或瀏覽器Cookie。一個cookie是放置在您的設備上的小文件。您可以指示您的瀏覽器拒絕所有Cookie或指示何時發送Cookie。但是，如果您不接受Cookie，您可能無法使用我們服務的某些部分。'),
            const Text('• 網頁信標。我們服務的某些部分和我們的電子郵件可能包含稱為網頁信標的小電子文件（也稱為clear gif、像素標籤和單像素gif），允許公司，例如，計算訪問過這些頁面的用戶或打開電子郵件的人數，以及其他相關網站統計（例如，記錄某個部分的受歡迎程度並驗證系統和服務器完整性）。'),
            const SizedBox(height: 8),
            const Text(
              'Cookie可以是"持久"或"會話"Cookie。持久Cookie在您離線時保留在您的個人電腦或移動設備上，而會話Cookie在您關閉網頁瀏覽器時被刪除。',
            ),
            const SizedBox(height: 8),
            const Text(
              '在法律要求的地方，我們僅在獲得您的同意後使用非必要cookie（例如分析、廣告和再營銷cookie）。您可以隨時使用我們的cookie偏好工具（如果可用）或通過您的瀏覽器/設備設置撤回或更改您的同意。撤回同意不會影響撤回前基於同意的處理的合法性。',
            ),
            const SizedBox(height: 8),
            const Text('我們為以下目的使用會話和持久Cookie：'),
            const SizedBox(height: 8),

            _buildCookieItem('必要/基本Cookie', '類型：會話Cookie\n管理員：我們\n目的：這些Cookie對於通過網站提供服務以及使您能夠使用其某些功能至關重要。它們有助於驗證用戶並防止用戶帳戶的欺詐使用。如果沒有這些Cookie，您要求提供的服務無法提供，我們僅使用這些Cookie來為您提供這些服務。'),
            _buildCookieItem('Cookie政策/通知接受Cookie', '類型：持久Cookie\n管理員：我們\n目的：這些Cookie識別用戶是否已接受在網站上使用cookie。'),
            _buildCookieItem('功能Cookie', '類型：持久Cookie\n管理員：我們\n目的：這些Cookie允許我們記住您在使用網站時做出的選擇，例如記住您的登錄詳細信息或語言偏好。這些Cookie的目的是為您提供更個性化的體驗，並避免您每次使用網站時都必須重新輸入您的偏好。'),

            const SizedBox(height: 8),
            const Text(
              '有關我們使用的cookie以及您對cookie的選擇的更多信息，請訪問我們的Cookie政策或我們的隱私權政策的Cookie部分。',
            ),
            const SizedBox(height: 24),

            // 使用您的個人數據
            const Text(
              '使用您的個人數據',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text('公司可能將個人數據用於以下目的：'),
            const SizedBox(height: 8),

            _buildPurposeItem('提供和維護我們的服務', '包括監控我們服務的使用。'),
            _buildPurposeItem('管理您的帳戶', '管理您作為服務用戶的註冊。您提供的個人數據可以讓您訪問作為註冊用戶可用的服務的不同功能。'),
            _buildPurposeItem('履行合同', '開發、遵守和承擔您通過服務購買的產品、物品或服務的購買合同，或與我們通過服務簽訂的任何其他合同。'),
            _buildPurposeItem('聯繫您', '通過電子郵件、電話、SMS或其他等效形式的電子通信（如移動應用程式的推送通知）聯繫您，關於更新或與功能、產品或約定的服務相關的信息通信，包括必要時的安全更新或合理實施。'),
            _buildPurposeItem('為您提供', '新聞、特別優惠和關於我們提供的其他商品、服務和事件的通用信息，這些商品、服務和事件與您已經購買或詢問的類似，除非您選擇不接收此類信息。'),
            _buildPurposeItem('管理您的請求', '處理和管理您對我們的請求。'),
            _buildPurposeItem('業務轉讓', '我們可能使用您的個人數據來評估或進行合併、剝離、重組、改組、解散，或其他銷售或轉讓我們的部分或全部資產，無論是作為持續經營還是作為破產、清算或類似程序的一部分，其中我們持有的關於我們服務用戶的個人數據是轉讓的資產之一。'),
            _buildPurposeItem('其他目的', '我們可能將您的信息用於其他目的，例如數據分析、識別使用趨勢、確定我們促銷活動的有效性以及評估和改進我們的服務、產品、服務、營銷和您的體驗。'),

            const SizedBox(height: 16),
            const Text('我們可能在以下情況下分享您的個人數據：'),
            const SizedBox(height: 8),

            _buildShareItem('與服務提供商', '我們可能與服務提供商分享您的個人數據，以監控和分析我們服務的使用，聯繫您。'),
            _buildShareItem('業務轉讓', '我們可能在合併、公司資產銷售、融資或收購我們全部或部分業務的過程中或談判期間分享或轉讓您的個人數據。'),
            _buildShareItem('與關聯公司', '我們可能與我們的關聯公司分享您的個人數據，在這種情況下，我們將要求這些關聯公司遵守本隱私權政策。關聯公司包括我們的母公司和任何其他子公司、合資夥伴或其他我們控制或與我們共同控制的公司。'),
            _buildShareItem('與業務夥伴', '我們可能與我們的業務夥伴分享您的個人數據，以向您提供某些產品、服務或促銷。'),
            _buildShareItem('與其他用戶', '如果我們的服務提供公共區域，當您在公共區域分享個人數據或以其他方式與其他用戶互動時，此類信息可能被所有用戶查看，並可能在外部公開分發。'),
            _buildShareItem('獲得您的同意', '我們可能為任何其他目的披露您的個人數據，並獲得您的同意。'),

            const SizedBox(height: 24),

            // 保留您的個人數據
            const Text(
              '保留您的個人數據',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '公司將僅在為本隱私權政策中規定的目的所必需的期間保留您的個人數據。我們將保留和使用您的個人數據，以符合我們的法律義務（例如，如果我們需要保留您的數據以遵守適用法律）、解決爭議以及執行我們的法律協議和政策。',
            ),
            const SizedBox(height: 16),
            const Text(
              '在可能的情況下，我們應用較短的保留期，並通過刪除、聚合或匿名化數據來減少可識別性。除非另有說明，以下保留期是最大期（"最多"），當相關目的不再需要數據時，我們可能會更快刪除或匿名化數據。我們根據處理目的和法律義務對不同類別的個人數據應用不同的保留期：',
            ),
            const SizedBox(height: 16),

            _buildRetentionItem('帳戶信息', [
              '用戶帳戶：在帳戶關係期間保留，加上帳戶關閉後最多24個月，以處理任何終止後問題或解決爭議。'
            ]),
            _buildRetentionItem('客戶支持數據', [
              '支持票據和通信：從票據關閉之日起最多24個月，以解決跟進查詢、跟踪服務質量並防範潛在法律索賠',
              '聊天記錄：最多24個月，用於質量保證和員工培訓目的。'
            ]),
            _buildRetentionItem('使用數據', [
              '網站分析數據（cookie、IP地址、設備識別符）：從收集之日起最多24個月，這允許我們分析趨勢同時尊重隱私原則。',
              '應用程式使用統計：最多24個月，以了解功能採用和服務改進。',
              '服務器日誌（IP地址、訪問時間）：最多24個月，用於安全監控和故障排除目的。'
            ]),

            const SizedBox(height: 16),
            const Text(
              '使用數據根據上述描述的保留期保留，並且只有在安全、欺詐預防或法律合規所必需時才會保留更長時間。',
            ),
            const SizedBox(height: 16),
            const Text('我們可能出於不同原因將個人數據保留超過上述期間：'),
            const SizedBox(height: 8),

            _buildBulletItem('法律義務：我們受法律要求保留特定數據（例如，稅務機關的財務記錄）。'),
            _buildBulletItem('法律索賠：數據對於建立、行使或辯護法律索賠是必要的。'),
            _buildBulletItem('您的明確請求：您要求我們保留特定信息。'),
            _buildBulletItem('技術限制：數據存在於計劃進行例行刪除的備份系統中。'),

            const SizedBox(height: 16),
            const Text('您可以通過聯繫我們請求有關我們將保留您的個人數據多長時間的信息。'),
            const SizedBox(height: 16),
            const Text('當保留期到期時，我們根據以下程序安全刪除或匿名化個人數據：'),
            const SizedBox(height: 8),

            _buildBulletItem('刪除：個人數據從我們的系統中移除，不再積極處理。'),
            _buildBulletItem('備份保留：殘餘副本可能在加密備份中保留有限期，與我們的備份保留計劃一致，除非出於安全、災難恢復或法律合規的必要性，否則不會恢復。'),
            _buildBulletItem('匿名化：在某些情況下，我們將個人數據轉換為無法追溯到您的匿名統計數據。此匿名數據可能無限期保留用於研究和分析。'),

            const SizedBox(height: 24),

            // 轉移您的個人數據
            const Text(
              '轉移您的個人數據',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '您的信息，包括個人數據，在公司的運營辦公室和處理相關方的任何其他地點進行處理。這意味著此信息可能被轉移到並保留在您的州、省、國家或其他政府管轄區以外的計算機上，那裡的數據保護法律可能與您管轄區的法律不同。',
            ),
            const SizedBox(height: 16),
            const Text(
              '在適用法律要求的地方，我們將確保您的個人數據的國際轉移受到適當保障和補充措施的約束。公司將採取所有合理必要的步驟，以確保您的數據得到安全處理，並符合本隱私權政策，除非有適當的控制措施，包括您的數據和其他個人信息的安全，否則不會將您的個人數據轉移給組織或國家。',
            ),
            const SizedBox(height: 24),

            // 刪除您的個人數據
            const Text(
              '刪除您的個人數據',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '您有權刪除或請求我們協助刪除我們收集的關於您的個人數據。',
            ),
            const SizedBox(height: 16),
            const Text(
              '我們的服務可能讓您能夠從服務內刪除關於您的某些信息。',
            ),
            const SizedBox(height: 16),
            const Text(
              '您可以隨時通過登錄您的帳戶（如果您有帳戶）並訪問允許您管理個人信息的帳戶設置部分來更新、修改或刪除您的信息。您也可以聯繫我們請求訪問、更正或刪除您提供給我們的任何個人數據。',
            ),
            const SizedBox(height: 16),
            const Text(
              '但是，請注意，當我們有法律義務或合法依據時，我們可能需要保留某些信息。',
            ),
            const SizedBox(height: 24),

            // 披露您的個人數據
            const Text(
              '披露您的個人數據',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              '業務交易',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '如果公司參與合併、收購或資產銷售，您的個人數據可能會被轉移。我們將在您的個人數據被轉移並受不同隱私權政策約束之前提供通知。',
            ),
            const SizedBox(height: 16),

            const Text(
              '執法',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '在某些情況下，如果法律要求或響應公共機構的有效請求（例如法院或政府機構），公司可能需要披露您的個人數據。',
            ),
            const SizedBox(height: 16),

            const Text(
              '其他法律要求',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '公司可能本著善意相信有必要披露您的個人數據，以：',
            ),
            const SizedBox(height: 8),

            _buildBulletItem('遵守法律義務'),
            _buildBulletItem('保護和捍衛公司的權利或財產'),
            _buildBulletItem('防止或調查與服務相關的可能不當行為'),
            _buildBulletItem('保護服務用戶或公眾的個人安全'),
            _buildBulletItem('保護免受法律責任'),

            const SizedBox(height: 24),

            // 您的個人數據的安全性
            const Text(
              '您的個人數據的安全性',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '您的個人數據的安全對我們很重要，但請記住，通過互聯網傳輸或電子存儲方法沒有100%的安全方法。雖然我們努力使用商業上合理的手段來保護您的個人數據，但我們無法保證其絕對安全。',
            ),
            const SizedBox(height: 24),

            // 兒童隱私
            const Text(
              '兒童隱私',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '我們的服務不針對16歲以下的任何人。我們不會故意收集16歲以下任何人的個人識別信息。如果您是父母或監護人，並且您知道您的孩子向我們提供了個人數據，請聯繫我們。如果我們發現我們在沒有驗證父母同意的情況下從16歲以下的任何人收集了個人數據，我們將採取步驟從我們的服務器中移除該信息。',
            ),
            const SizedBox(height: 16),
            const Text(
              '如果我們需要依賴同意作為處理您的信息的法律依據，並且您的國家要求父母同意，我們可能需要在收集和使用該信息之前獲得您的父母的同意。',
            ),
            const SizedBox(height: 24),

            // 到其他網站的鏈接
            const Text(
              '到其他網站的鏈接',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '我們的服務可能包含指向不由我們運營的其他網站的鏈接。如果您點擊第三方鏈接，您將被定向到該第三方的網站。我們強烈建議您查看您訪問的每個網站的隱私權政策。',
            ),
            const SizedBox(height: 16),
            const Text(
              '我們對任何第三方網站或服務的內容、隱私權政策或實踐沒有控制權，也不承擔任何責任。',
            ),
            const SizedBox(height: 24),

            // 本隱私權政策的更改
            const Text(
              '本隱私權政策的更改',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '我們可能會不時更新我們的隱私權政策。我們將通過在此頁面上發布新的隱私權政策來通知您任何更改。',
            ),
            const SizedBox(height: 16),
            const Text(
              '我們將通過電子郵件和/或在我們的服務上發布突出通知，在更改生效之前讓您知道，並更新本隱私權政策頂部的"最後更新"日期。',
            ),
            const SizedBox(height: 16),
            const Text(
              '建議您定期查看本隱私權政策以了解任何更改。本隱私權政策的更改在在此頁面上發布時生效。',
            ),
            const SizedBox(height: 24),

            // 聯繫我們
            const Text(
              '聯繫我們',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text('如果您對本隱私權政策有任何疑問，您可以聯繫我們：'),
            const SizedBox(height: 8),
            const Text('• 通過電子郵件：coseligtest@gmail.com'),
          ],
        ),
      ),
    );
  }

  static Widget _buildDefinitionItem(String term, String definition) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            term,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(definition),
        ],
      ),
    );
  }

  static Widget _buildCookieItem(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(content),
        ],
      ),
    );
  }

  static Widget _buildPurposeItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• $title',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(description),
        ],
      ),
    );
  }

  static Widget _buildShareItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(description),
        ],
      ),
    );
  }

  static Widget _buildRetentionItem(String title, List<String> items) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: Text('• $item'),
          )),
        ],
      ),
    );
  }

  static Widget _buildBulletItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text('• $text'),
    );
  }
}