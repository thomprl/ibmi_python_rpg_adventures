let notificationTimeout; 

function showNotification(message, type) {
    const notification = document.getElementById('notification');
    const messageElement = document.getElementById('notification-message');
    notification.className = type;
    messageElement.textContent = message;
    notification.style.display = 'block';

    // Clear any existing timeout
    if (notificationTimeout) {
        clearTimeout(notificationTimeout);
    }

    // Auto-hide after 10 seconds
    notificationTimeout = setTimeout(hideNotification, 10000);

}

function hideNotification() {
    document.getElementById('notification').style.display = 'none';
}

function deleteProduct(productNumber) {
    if (confirm(`Are you sure you want to delete product: ${productNumber}?`)) {
        $.ajax({
            url: '/api',
            type: 'POST',
            contentType: 'application/json',
            data: JSON.stringify({
                app: 'product',
                action: 'delete',
                productnumber: productNumber
            }),
            success: function (response) {
                if (response.success) {
                    $('#myTable').DataTable().ajax.reload();
                    showNotification(response.message, 'success');
                } else {
                    showNotification(response.message, 'error');
                }
            },
            error: function (xhr, status, error) {
                showNotification('Error deleting product: ' + error, 'error');
            }
        });
    }
}

$(document).ready(function () {
    var table = $('#myTable').DataTable({
        ajax: {
            url: '/api?app=product&action=getproductlist',
            type: 'GET',
            dataSrc: 'data'
        },
        columns: [
            { 'data': 'ProductNumber' },
            { 'data': 'Description' },
            { 'data': 'Cost' },
            { 'data': 'UnitOfMeasure' },
            { 'data': 'Category' },
            {
                'data': null,
                'render': function (data, type, row) {
                    return `
                                <div class="action-buttons">
                                    <i class="fas fa-edit" title="Edit"></i>
                                    <i class="fas fa-trash-alt" onclick="deleteProduct('${row.ProductNumber}')" title="Delete"></i>
                                </div>
                            `;
                }
            }
        ],
        pageLength: 10,
        order: [[1, 'asc']]
    });
});
