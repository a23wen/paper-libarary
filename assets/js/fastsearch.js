import * as params from '@params';

let fuse;
let resList = document.getElementById('searchResults');
let sInput = document.getElementById('searchInput');
let first, last, current_elem = null
let resultsAvailable = false;

function escapeHTML(value) {
    const div = document.createElement('div');
    div.textContent = value ?? '';
    return div.innerHTML;
}

function asList(value) {
    if (Array.isArray(value)) return value.filter(Boolean);
    if (value) return [value];
    return [];
}

function statusLabel(status) {
    if (status === 'completed') return '已完成';
    if (status === 'reading') return '正在阅读';
    if (status === 'to-read') return '待阅读';
    return status || '';
}

function renderResult(item) {
    const categories = asList(item.categories);
    const authors = asList(item.authors).slice(0, 3);
    const meta = [
        categories.join(' / '),
        item.year,
        item.venues,
        statusLabel(item.status),
        item.rating > 0 ? `${item.rating}/5` : ''
    ].filter(Boolean);

    const authorText = authors.length ? `<div class="paper-search-authors">${escapeHTML(authors.join(', '))}${asList(item.authors).length > 3 ? ' 等' : ''}</div>` : '';
    const summary = item.summary ? `<p>${escapeHTML(item.summary)}</p>` : '';

    return `<li class="post-entry paper-search-result">
        <header class="entry-header">
            <span class="paper-search-title">${escapeHTML(item.title)}&nbsp;»</span>
        </header>
        <div class="paper-search-meta">${meta.map((part) => `<span>${escapeHTML(part)}</span>`).join('')}</div>
        ${authorText}
        ${summary}
        <a href="${item.permalink}" aria-label="${escapeHTML(item.title)}"></a>
    </li>`;
}

window.onload = function () {
    let xhr = new XMLHttpRequest();
    xhr.onreadystatechange = function () {
        if (xhr.readyState === 4) {
            if (xhr.status === 200) {
                let data = JSON.parse(xhr.responseText);
                if (data) {
                    let options = {
                        distance: 100,
                        threshold: 0.4,
                        ignoreLocation: true,
                        keys: [
                            'title',
                            'permalink',
                            'summary',
                            'content',
                            'categories',
                            'authors',
                            'venues',
                            'year',
                            'status',
                            'rating'
                        ]
                    };
                    if (params.fuseOpts) {
                        options = {
                            isCaseSensitive: params.fuseOpts.iscasesensitive ?? false,
                            includeScore: params.fuseOpts.includescore ?? false,
                            includeMatches: params.fuseOpts.includematches ?? false,
                            minMatchCharLength: params.fuseOpts.minmatchcharlength ?? 1,
                            shouldSort: params.fuseOpts.shouldsort ?? true,
                            findAllMatches: params.fuseOpts.findallmatches ?? false,
                            keys: params.fuseOpts.keys ?? options.keys,
                            location: params.fuseOpts.location ?? 0,
                            threshold: params.fuseOpts.threshold ?? 0.4,
                            distance: params.fuseOpts.distance ?? 100,
                            ignoreLocation: params.fuseOpts.ignorelocation ?? true
                        }
                    }
                    fuse = new Fuse(data, options);
                }
            } else {
                console.log(xhr.responseText);
            }
        }
    };
    xhr.open('GET', "../index.json");
    xhr.send();
}

function activeToggle(ae) {
    document.querySelectorAll('.focus').forEach(function (element) {
        element.classList.remove("focus")
    });
    if (ae) {
        ae.focus()
        document.activeElement = current_elem = ae;
        ae.parentElement.classList.add("focus")
    } else {
        document.activeElement.parentElement.classList.add("focus")
    }
}

function reset() {
    resultsAvailable = false;
    resList.innerHTML = sInput.value = '';
    sInput.focus();
}

sInput.onkeyup = function () {
    if (fuse) {
        let query = this.value.trim();
        if (!query) {
            resList.innerHTML = '';
            resultsAvailable = false;
            return;
        }

        let results;
        if (params.fuseOpts) {
            results = fuse.search(query, {limit: params.fuseOpts.limit});
        } else {
            results = fuse.search(query);
        }
        if (results.length !== 0) {
            resList.innerHTML = results.map((result) => renderResult(result.item)).join('');
            resultsAvailable = true;
            first = resList.firstChild;
            last = resList.lastChild;
        } else {
            resultsAvailable = false;
            resList.innerHTML = '<li class="paper-search-empty">没有找到匹配的论文。</li>';
        }
    }
}

sInput.addEventListener('search', function () {
    if (!this.value) reset()
})

document.onkeydown = function (e) {
    let key = e.key;
    let ae = document.activeElement;

    let inbox = document.getElementById("searchbox").contains(ae)

    if (ae === sInput) {
        let elements = document.getElementsByClassName('focus');
        while (elements.length > 0) {
            elements[0].classList.remove('focus');
        }
    } else if (current_elem) ae = current_elem;

    if (key === "Escape") {
        reset()
    } else if (!resultsAvailable || !inbox) {
        return
    } else if (key === "ArrowDown") {
        e.preventDefault();
        if (ae == sInput) {
            activeToggle(resList.firstChild.lastChild);
        } else if (ae.parentElement != last) {
            activeToggle(ae.parentElement.nextSibling.lastChild);
        }
    } else if (key === "ArrowUp") {
        e.preventDefault();
        if (ae.parentElement == first) {
            activeToggle(sInput);
        } else if (ae != sInput) {
            activeToggle(ae.parentElement.previousSibling.lastChild);
        }
    } else if (key === "ArrowRight" || key === "Enter") {
        if (ae !== sInput) {
            ae.click();
        }
    }
}
