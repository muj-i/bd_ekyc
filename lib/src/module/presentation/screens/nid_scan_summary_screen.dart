

import 'package:bd_ekyc/exports.dart';

class NidScanSummaryScreen extends StatelessWidget {
  final NidScanResult frontResult;
  final NidScanResult backResult;

  const NidScanSummaryScreen({
    super.key,
    required this.frontResult,
    required this.backResult,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("NID Scan Complete"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () =>
              Navigator.of(context).popUntil((route) => route.isFirst),
          icon: const Icon(Icons.home),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Success Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 32),
                  SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      "NID Scan Completed Successfully!",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Extracted Information
            Stack(
              children: [
                _buildInfoCard(
                  title: "Extracted Information",
                  icon: Icons.person,
                  children: [
                    _buildInfoRow("NID Number", frontResult.nidNumber ?? "N/A"),
                    _buildInfoRow("Full Name", frontResult.nidName ?? "N/A"),
                    _buildInfoRow(
                      "Date of Birth",
                      frontResult.nidDateOfBirth ?? "N/A",
                    ),
                    (backResult.nidIssueDate != null)
                        ? _buildInfoRow("Issue Date", backResult.nidIssueDate!)
                        : SizedBox.shrink(),
                    _buildInfoRow(
                      "NID Type",
                      frontResult.isSmartNid == true ? "Smart NID" : "Old NID",
                    ),
                    _buildInfoRow(
                      "13-Digit Converted",
                      frontResult.is13DigitNid == true ? "Yes" : "No",
                    ),
                  ],
                ),
                Positioned(
                  right: 16,
                  top: 48,
                  child: InkWell(
                    onTap: () {
                      showWarningToast(
                        context,
                        message:
                            '13 digit NID found, 4 digit birth year added to create 17 digit NID.',
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: PackageColors.deepYellow.withValues(alpha: .2),
                        shape: BoxShape.circle,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Icon(
                          Icons.info_outline_rounded,
                          size: 16,
                          color: PackageColors.deepYellow,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Captured Images
            _buildInfoCard(
              title: "Captured Images",
              icon: Icons.camera_alt,
              children: [
                Row(
                  children: [
                    // Front Side Image
                    Expanded(
                      child: Column(
                        children: [
                          const Text(
                            "Front Side",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          frontResult.frontSideImageFile != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    frontResult.frontSideImageFile!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                  ),
                                )
                              : frontResult.imageFile != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    frontResult.imageFile!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                  ),
                                )
                              : const Center(
                                  child: Icon(
                                    Icons.image_not_supported,
                                    color: Colors.grey,
                                  ),
                                ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Back Side Image
                    Expanded(
                      child: Column(
                        children: [
                          const Text(
                            "Back Side",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          backResult.backSideImageFile != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    backResult.backSideImageFile!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                  ),
                                )
                              : backResult.imageFile != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    backResult.imageFile!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                  ),
                                )
                              : const Center(
                                  child: Icon(
                                    Icons.image_not_supported,
                                    color: Colors.grey,
                                  ),
                                ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Validation Status
            _buildInfoCard(
              title: "Validation Status",
              icon: Icons.verified,
              children: [
                _buildStatusRow(
                  "Front Side Data",
                  frontResult.success,
                  frontResult.success ? "Valid" : "Invalid",
                ),
                _buildStatusRow(
                  "Back Side Data",
                  backResult.success,
                  backResult.success ? "Valid" : "Invalid",
                ),
                _buildStatusRow(
                  "Cross Validation",
                  frontResult.success && backResult.success,
                  frontResult.success && backResult.success
                      ? "Front & Back Match"
                      : "Validation Failed",
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(
                      context,
                    ).popUntil((route) => route.isFirst),
                    icon: const Icon(Icons.refresh),
                    label: const Text("Scan Again"),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("KYC data ready for submission!"),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    icon: const Icon(Icons.check),
                    label: const Text("Submit KYC"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.green, size: 24),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, bool isValid, String status) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Icon(
            isValid ? Icons.check_circle : Icons.error,
            color: isValid ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            status,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isValid ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}
